require "socket"
require "json"

# Minimal HTTP client for the router's bare-bones web server (no Content-Length,
# body ends when the connection closes; rejects Net::HTTP's default headers).
class RouterClient
  class Error < StandardError; end

  HOST    = ENV.fetch("ROUTER_HOST", "192.168.1.1")
  PORT    = 80
  TIMEOUT = 8

  def proc_get(params = {})
    defaults = { multi_data: 1, isTest: false, sms_received_flag: 0, sts_received_flag: 0 }
    query = defaults.merge(params).map { |k, v| "#{k}=#{v.to_s.delete(' ')}" }.join("&") # commas stay unescaped
    request = "GET /reqproc/proc_get?#{query} HTTP/1.1\r\n" \
              "Host: #{HOST}\r\n" \
              "User-Agent: curl/7.81.0\r\n" \
              "Accept: */*\r\n" \
              "Referer: http://#{HOST}/index.html\r\n\r\n"

    raw = exchange(request)
    Rails.logger.debug("[RouterClient] raw response: #{raw.inspect}")
    json = raw[/\{.*\}/m] # headers vary on this router; take just the JSON object
    raise Error, "router sent no JSON (got #{raw.to_s[0, 80].inspect})" if json.nil?

    data = JSON.parse(json)
    raise Error, "router replied: #{data['result']}" if data.key?("result") && data.size == 1
    data
  rescue JSON::ParserError
    raise Error, "router returned non-JSON"
  rescue SystemCallError, SocketError, IOError => e
    raise Error, "router unreachable: #{e.class}"
  end

  private

  def exchange(request)
    clock = -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
    deadline = clock.call + TIMEOUT
    sock = Socket.tcp(HOST, PORT, connect_timeout: 5)
    begin
      sock.write(request)
      buf = +""
      loop do
        left = deadline - clock.call
        raise Error, "router timed out" if left <= 0
        raise Error, "router timed out" unless IO.select([ sock ], nil, nil, left)
        chunk = sock.read_nonblock(4096, exception: false)
        next if chunk == :wait_readable
        break if chunk.nil? # connection closed = end of body
        buf << chunk
      end
      buf
    ensure
      sock.close
    end
  end
end
