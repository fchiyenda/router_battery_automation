class AddStepPercentsToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :battery_automation_settings, :step_percents, :string, null: false, default: "0,25,50,75,100"
  end
end
