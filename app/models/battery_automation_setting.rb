class BatteryAutomationSetting < ApplicationRecord
  # battery_scale_max = how many steps the router reports (4 = bars, 100 = real percent)
  validates :battery_scale_max, numericality: { only_integer: true, in: 1..100 }
  validates :start_charging_at, :stop_charging_at, numericality: { only_integer: true, in: 0..100 }
  validates :monitoring_interval, numericality: { only_integer: true, in: 15..3600 }
  validates :confirmations_required, numericality: { only_integer: true, in: 1..5 }
  validate { errors.add(:start_charging_at, "must be below stop threshold") if start_charging_at.to_i >= stop_charging_at.to_i }

  LOCK_SECONDS = 90

  def self.instance = first || create!

  # Atomic, non-blocking lock so two jobs never talk to the devices at once.
  def acquire_lock!
    now = Time.current
    self.class.where(id: id).where("locked_until IS NULL OR locked_until < ?", now)
        .update_all(locked_until: now + LOCK_SECONDS.seconds) == 1
  end

  def release_lock! = self.class.where(id: id).update_all(locked_until: nil)
end
