# Self-rescheduling job. Surplus chains (e.g. extra boot kicks) exit via next_run_at.
class BatteryMonitorJob < ApplicationJob
  queue_as :default

  def perform
    s = BatteryAutomationSetting.instance
    return if s.next_run_at && s.next_run_at > 5.seconds.from_now
    begin
      BatteryAutomation::Runner.call
    ensure
      s.update_columns(next_run_at: Time.current + s.monitoring_interval)
      self.class.set(wait: s.monitoring_interval.seconds).perform_later
    end
  end
end
