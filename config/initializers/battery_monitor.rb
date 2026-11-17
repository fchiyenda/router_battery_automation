# Runs the battery monitor in ONE background thread inside the Rails server process.
# No job chain to die: the thread loops forever, and any error is logged and retried.
Rails.application.config.after_initialize do
  next unless defined?(Rails::Server) || ENV["BATTERY_MONITOR"] == "1"

  # A global (not a class variable) so code reloading in development can't start a second thread.
  next if $battery_monitor_thread&.alive?

  $battery_monitor_thread = Thread.new do
    Thread.current.name = "battery-monitor"
    Thread.current.report_on_exception = false
    sleep 5 # let boot finish
    Rails.logger.info("[BatteryAutomation] monitor thread started")

    loop do
      wait = 60
      begin
        Rails.application.executor.wrap do
          wait = BatteryAutomationSetting.instance.monitoring_interval
          BatteryAutomation::Runner.call
        end
        Rails.logger.info("[BatteryAutomation] cycle done, next in #{wait}s")
      rescue StandardError => e
        Rails.logger.error("[BatteryAutomation] cycle crashed: #{e.class}: #{e.message}")
        wait = 15
      end
      sleep wait
    end
  end
end
