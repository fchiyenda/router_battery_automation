require "open3"
require "json"

# Talks to the plug locally (no Tuya cloud) through bin/tuya_plug.py.
class TuyaLocalPlug
  class Error < StandardError; end

  SCRIPT = Rails.root.join("bin", "tuya_plug.py").to_s

  def switch_on? = run("status").fetch("on")

  def set_switch(on)
    run(on ? "on" : "off")
  end

  private

  def run(cmd)
    out, err, status = Open3.capture3("timeout", "15", "python3", SCRIPT, cmd)
    data = begin
      JSON.parse(out)
    rescue JSON::ParserError
      raise Error, "no valid output from plug script: #{err.to_s.strip.presence || 'timeout?'}"
    end
    raise Error, data["error"] if data["error"] || !status.success?
    data
  end
end
