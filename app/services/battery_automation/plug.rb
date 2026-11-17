module BatteryAutomation
  # ADAPTER: wraps your existing Tuya Local service (192.168.1.186:6668, local key, confirmed protocol version).
  class Plug
    class Error < StandardError; end
    RETRIES = 3

    def self.on? = with_retry { read_state }

    # Sets state, then verifies by reading it back. Raises Error if it fails after retries.
    def self.set(on)
      with_retry do
        write_state(on)
        sleep 1
        raise "verify failed (wanted #{on})" unless read_state == on
      end
      on
    end

    def self.with_retry
      tries = 0
      begin
        yield
      rescue StandardError => e
        tries += 1
        if tries < RETRIES
          sleep(tries * 2)
          retry
        end
        raise Error, "#{e.class}: #{e.message}"
      end
    end

    # TODO: map to your existing Tuya Local service (switch datapoint, usually "1"). Use short timeouts.
    def self.read_state = TuyaLocalPlug.new.switch_on?        # => true/false
    def self.write_state(on) = TuyaLocalPlug.new.set_switch(on)
  end
end
