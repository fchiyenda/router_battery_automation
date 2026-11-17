class SwitchToPercentScale < ActiveRecord::Migration[8.0]
  def up
    change_column_default :battery_automation_settings, :start_charging_at, 25
    change_column_default :battery_automation_settings, :stop_charging_at, 100
    # Convert existing step values (0 to 4) to percent
    execute "UPDATE battery_readings SET level = level * 25"
    execute "UPDATE battery_automation_settings SET start_charging_at = 25, stop_charging_at = 100, " \
            "last_battery_level = last_battery_level * 25, low_streak = 0, full_streak = 0"
  end

  def down; end
end
