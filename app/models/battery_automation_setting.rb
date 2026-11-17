class BatteryAutomationSetting < ApplicationRecord
  # battery_scale_max = how many steps the router reports (4 = bars, 100 = real percent)
  validates :battery_scale_max, numericality: { only_integer: true, in: 1..100 }
  validates :start_charging_at, :stop_charging_at, numericality: { only_integer: true, in: 0..100 }
  validates :monitoring_interval, numericality: { only_integer: true, in: 15..3600 }
  validates :confirmations_required, numericality: { only_integer: true, in: 1..5 }
  validate { errors.add(:start_charging_at, "must be below stop threshold") if start_charging_at.to_i >= stop_charging_at.to_i }
  validate :step_percents_valid

  LOCK_SECONDS = 90

  def self.instance = first || create!

  # "0,25,50,75,100" -> [0, 25, 50, 75, 100]
  def step_percent_list
    step_percents.to_s.split(",").map { |v| Integer(v.strip) }
  rescue ArgumentError
    []
  end

  # Percent shown for a router step. Falls back to an even split if the map is unusable.
  def percent_for(step)
    return step if battery_scale_max >= 100
    step_percent_list[step] || (step * 100.0 / battery_scale_max).round
  end

  # Atomic, non-blocking lock so two jobs never talk to the devices at once.
  def acquire_lock!
    now = Time.current
    self.class.where(id: id).where("locked_until IS NULL OR locked_until < ?", now)
        .update_all(locked_until: now + LOCK_SECONDS.seconds) == 1
  end

  def release_lock! = self.class.where(id: id).update_all(locked_until: nil)

  private

  def step_percents_valid
    return if battery_scale_max.to_i >= 100
    list = step_percent_list
    ok = list.size == battery_scale_max.to_i + 1 &&
         list.all? { |v| v.between?(0, 100) } &&
         list.each_cons(2).all? { |a, b| a < b }
    errors.add(:step_percents, "must be #{battery_scale_max.to_i + 1} increasing numbers from 0 to 100, like 0,25,50,75,100") unless ok
  end
end