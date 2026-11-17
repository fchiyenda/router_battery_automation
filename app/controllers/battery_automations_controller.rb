class BatteryAutomationsController < ApplicationController
  # Add your authentication here, e.g. before_action :authenticate_user!
  before_action :load_setting

  def show
    @events   = BatteryEvent.order(created_at: :desc).limit(15)
    @latest   = BatteryReading.order(:created_at).last
    @readings = BatteryReading.where("created_at > ?", 24.hours.ago).order(:created_at).pluck(:created_at, :level)
  end

  def update
    permitted = params.require(:battery_automation_setting).permit(:start_charging_at, :stop_charging_at, :monitoring_interval, :confirmations_required, :battery_scale_max)
    if @setting.update(permitted)
      redirect_to battery_automation_path, notice: "Settings saved"
    else
      redirect_to battery_automation_path, alert: @setting.errors.full_messages.to_sentence
    end
  end

  def toggle
    @setting.update!(enabled: !@setting.enabled, low_streak: 0, full_streak: 0)
    redirect_to battery_automation_path, notice: "Automation #{@setting.enabled ? 'enabled' : 'disabled'}"
  end

  def plug_on  = manual(true)
  def plug_off = manual(false)

  private

  def load_setting = @setting = BatteryAutomationSetting.instance

  def manual(on)
    BatteryAutomation::Plug.set(on)
    @setting.update!(charging_active: on, last_switch_action: on ? "ON" : "OFF", last_switch_at: Time.current, low_streak: 0, full_streak: 0)
    BatteryEvent.log(on ? :manual_on : :manual_off, level: @setting.last_battery_level, message: "manual")
    redirect_to battery_automation_path, notice: "Plug #{on ? 'ON' : 'OFF'}"
  rescue StandardError => e
    redirect_to battery_automation_path, alert: "Plug error: #{e.message}"
  end
end
