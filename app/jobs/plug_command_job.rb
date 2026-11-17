require "timeout"

class PlugCommandJob < ApplicationJob
  queue_as :default
  MAX_WAITS = 10

  def perform(on)
    s = BatteryAutomationSetting.instance

    unless s.acquire_lock! # a monitoring check is talking to the plug; try again shortly
      return retry_job(wait: 3.seconds) if executions < MAX_WAITS
      BatteryEvent.log(:plug_error, level: s.last_battery_level, message: "Manual command dropped: plug busy")
      return BatteryAutomation::Broadcaster.call
    end

    begin
      Timeout.timeout(60) { BatteryAutomation::Plug.set(on) }
      s.update!(charging_active: on, last_switch_action: on ? "ON" : "OFF", last_switch_at: Time.current,
                low_streak: 0, full_streak: 0, error_message: nil)
      BatteryEvent.log(on ? :manual_on : :manual_off, level: s.last_battery_level, message: "manual")
    rescue StandardError => e
      s.update!(error_message: "Plug: #{e.message}")
      BatteryEvent.log(:plug_error, level: s.last_battery_level, message: "Manual command failed: #{e.message}")
    ensure
      s.release_lock!
      BatteryAutomation::Broadcaster.call
    end
  end
end
