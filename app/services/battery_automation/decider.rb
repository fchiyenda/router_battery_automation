module BatteryAutomation
  # Pure logic: plug state + battery level -> action. Hysteresis comes from the plug's actual state,
  # so a reading just below full after a charge never switches the plug back ON.
  class Decider
    Decision = Struct.new(:action, :low_streak, :full_streak)

    def self.call(level:, plug_on:, start_at:, stop_at:, required:, low_streak: 0, full_streak: 0, full_signal: false)
      low  = !plug_on && level <= start_at ? low_streak + 1 : 0
      full = plug_on && (level >= stop_at || full_signal) ? full_streak + 1 : 0
      action = if !plug_on && low >= required then :turn_on
      elsif plug_on && full >= required then :turn_off
      else :none
      end
      Decision.new(action, action == :none ? low : 0, action == :none ? full : 0)
    end
  end
end
