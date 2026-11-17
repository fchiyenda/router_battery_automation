class BatteryAutomationsController < ApplicationController
  # Add your authentication here, e.g. before_action :authenticate_user!
  before_action :load_setting

  def show
    @events      = BatteryEvent.order(created_at: :desc).limit(15)
    @latest      = BatteryReading.order(:created_at).last
    @readings    = BatteryReading.where("created_at > ?", 24.hours.ago).order(:created_at).pluck(:created_at, :level)
    @calibration = BatteryAutomation::Calibration.call(@setting)
  end

  def update
    permitted = params.require(:battery_automation_setting).permit(
      :start_charging_at, :stop_charging_at, :monitoring_interval,
      :confirmations_required, :battery_scale_max, :use_charge_full, :step_percents
    )
    if @setting.update(permitted)
      BatteryAutomation::Broadcaster.call
      redirect_to battery_automation_path, notice: "Settings saved", status: :see_other
    else
      redirect_to battery_automation_path, alert: @setting.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def toggle
    @setting.update!(enabled: !@setting.enabled, low_streak: 0, full_streak: 0)
    BatteryAutomation::Broadcaster.call
    redirect_to battery_automation_path, notice: "Automation #{@setting.enabled ? 'enabled' : 'disabled'}", status: :see_other
  end

  def plug_on  = manual(true)
  def plug_off = manual(false)

  private

  def load_setting = @setting = BatteryAutomationSetting.instance

  # Returns immediately; the job talks to the plug and the page updates over the socket.
  def manual(on)
    PlugCommandJob.perform_later(on)
    redirect_to battery_automation_path, notice: "Plug #{on ? 'ON' : 'OFF'} command sent", status: :see_other
  end
end
