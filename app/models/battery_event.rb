class BatteryEvent < ApplicationRecord
  def self.log(kind, level: nil, message: nil)
    Rails.logger.info("[BatteryAutomation] #{kind} level=#{level} #{message}")
    create!(kind: kind, battery_level: level, message: message&.truncate(250), created_at: Time.current)
  end
end
