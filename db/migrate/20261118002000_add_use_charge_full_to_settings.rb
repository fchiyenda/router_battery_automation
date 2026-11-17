class AddUseChargeFullToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :battery_automation_settings, :use_charge_full, :boolean, null: false, default: true
  end
end
