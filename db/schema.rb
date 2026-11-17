# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_11_18_002000) do
  create_table "battery_automation_settings", force: :cascade do |t|
    t.boolean "enabled", default: true, null: false
    t.integer "start_charging_at", default: 25, null: false
    t.integer "stop_charging_at", default: 100, null: false
    t.integer "monitoring_interval", default: 60, null: false
    t.integer "confirmations_required", default: 2, null: false
    t.integer "low_streak", default: 0, null: false
    t.integer "full_streak", default: 0, null: false
    t.integer "last_battery_level"
    t.boolean "charging_active", default: false, null: false
    t.string "last_switch_action"
    t.datetime "last_switch_at"
    t.datetime "last_checked_at"
    t.datetime "next_run_at"
    t.datetime "locked_until"
    t.string "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "battery_scale_max", default: 4, null: false
    t.boolean "use_charge_full", default: true, null: false
  end

  create_table "battery_events", force: :cascade do |t|
    t.string "kind", null: false
    t.integer "battery_level"
    t.string "message"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_battery_events_on_created_at"
  end

  create_table "battery_readings", force: :cascade do |t|
    t.integer "level", null: false
    t.boolean "plug_on"
    t.json "raw", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_battery_readings_on_created_at"
  end
end
