class CreateBatteryAutomation < ActiveRecord::Migration[7.1]
  def change
    create_table :battery_automation_settings do |t|
      t.boolean  :enabled, null: false, default: true
      t.integer  :start_charging_at, null: false, default: 3
      t.integer  :stop_charging_at, null: false, default: 100
      t.integer  :monitoring_interval, null: false, default: 60
      t.integer  :confirmations_required, null: false, default: 2
      t.integer  :low_streak, null: false, default: 0
      t.integer  :full_streak, null: false, default: 0
      t.integer  :last_battery_level
      t.boolean  :charging_active, null: false, default: false
      t.string   :last_switch_action
      t.datetime :last_switch_at
      t.datetime :last_checked_at
      t.datetime :next_run_at
      t.datetime :locked_until
      t.string   :error_message
      t.timestamps
    end
    create_table :battery_readings do |t|
      t.integer :level, null: false
      t.boolean :plug_on
      t.json :raw, null: false, default: {} # battery_charge_full, battery_charging, charge_type, power_exist
      t.datetime :created_at, null: false
    end
    add_index :battery_readings, :created_at
    create_table :battery_events do |t|
      t.string  :kind, null: false
      t.integer :battery_level
      t.string  :message
      t.datetime :created_at, null: false
    end
    add_index :battery_events, :created_at
  end
end
