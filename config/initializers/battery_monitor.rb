# Resume automation after a restart (safe: duplicate chains exit, runner is locked).
Rails.application.config.after_initialize do
  next unless defined?(Rails::Server) || defined?(Sidekiq::CLI)
  begin
    BatteryMonitorJob.perform_later if ActiveRecord::Base.connection.table_exists?(:battery_automation_settings)
  rescue StandardError => e
    Rails.logger.warn("[BatteryAutomation] boot kick failed: #{e.message}")
  end
end
