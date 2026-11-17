class AddBatteryScaleToSettings < ActiveRecord::Migration[8.0]
  def up
    add_column :battery_automation_settings, :battery_scale_max, :integer, null: false, default: 4
    change_column_default :battery_automation_settings, :start_charging_at, from: 3, to: 1
    change_column_default :battery_automation_settings, :stop_charging_at, from: 100, to: 4
    execute "UPDATE battery_automation_settings SET start_charging_at = 1, stop_charging_at = 4"
  end

  def down
    remove_column :battery_automation_settings, :battery_scale_max
  end
end
