require "timeout"

module BatteryAutomation
  class Runner
    HARD_LIMIT = 75 # seconds for one whole check

    def self.call = new.call

    def call
      s = BatteryAutomationSetting.instance
      return unless s.acquire_lock!
      begin
        Timeout.timeout(HARD_LIMIT) { run(s) }
      rescue Timeout::Error
        fail!(s, :timeout, "Check timed out after #{HARD_LIMIT}s")
      ensure
        s.release_lock!
        Broadcaster.call
      end
    end

    private

    def run(s)
      reading = begin
        RouterBattery.fetch
      rescue StandardError => e
        return fail!(s, :router_error, "Router: #{e.message}") # never switches on a failed read
      end

      BatteryReading.create!(level: reading.level, raw: reading.raw, created_at: Time.current)
      s.update!(last_battery_level: reading.level, last_checked_at: Time.current)
      Broadcaster.call # show the new level immediately, before the plug is contacted

      plug_on = begin
        Plug.on?
      rescue StandardError => e
        return fail!(s, :plug_error, "Plug: #{e.message}")
      end

      BatteryReading.order(:created_at).last.update!(plug_on: plug_on)
      s.update!(charging_active: plug_on, error_message: nil)
      return unless s.enabled

      # The router's "full" flag only counts while the battery is above the start threshold.
      full_signal = s.use_charge_full && reading.charge_full && reading.level > s.start_charging_at

      d = Decider.call(level: reading.level, plug_on: plug_on, start_at: s.start_charging_at,
                       stop_at: s.stop_charging_at, required: s.confirmations_required,
                       low_streak: s.low_streak, full_streak: s.full_streak, full_signal: full_signal)
      s.update!(low_streak: d.low_streak, full_streak: d.full_streak)
      return if d.action == :none

      want_on = d.action == :turn_on
      begin
        Plug.set(want_on)
        s.update!(charging_active: want_on, last_switch_action: want_on ? "ON" : "OFF", last_switch_at: Time.current)
        BatteryEvent.log(want_on ? :switch_on : :switch_off, level: reading.level, message: "automatic")
      rescue StandardError => e
        fail!(s, :plug_error, "Switch failed: #{e.message}") # retried next cycle
      end
    end

    def fail!(s, kind, msg)
      s.update!(error_message: msg, last_checked_at: Time.current)
      BatteryEvent.log(kind, level: s.last_battery_level, message: msg)
      nil
    end
  end
end
