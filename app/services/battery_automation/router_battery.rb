module BatteryAutomation
  # ADAPTER around the router client. Converts the router's step value to percent.
  class RouterBattery
    class Invalid < StandardError; end
    Result = Struct.new(:level, :raw)

    def self.fetch(steps: BatteryAutomationSetting.instance.battery_scale_max)
      data = fetch_raw
      raise Invalid, "battery not installed (battery_exist=#{data['battery_exist'].inspect})" unless data["battery_exist"].to_s == "1"
      v = data["battery_value"].to_s.strip
      raise Invalid, "invalid battery_value #{v.inspect}" unless v.match?(/\A\d{1,3}\z/) && v.to_i <= steps

      percent = (v.to_i * 100.0 / steps).round
      raw = data.slice("battery_value", "battery_charge_full", "battery_charging", "charge_type", "power_exist")
      Result.new(percent, raw)
    end

    # Must return a Hash and RAISE on timeout/HTTP error. Never return 0 on failure.
    def self.fetch_raw
      RouterClient.new.proc_get(cmd: "battery_value,battery_exist,battery_charge_full,battery_charging,charge_type,power_exist")
    end
  end
end
