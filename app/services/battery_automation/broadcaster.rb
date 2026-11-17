module BatteryAutomation
  # Pushes fresh HTML to every open dashboard. Never raises: a broadcast problem must not break monitoring.
  class Broadcaster
    STREAM = "battery_automation".freeze

    def self.call
      s      = BatteryAutomationSetting.instance
      latest = BatteryReading.order(:created_at).last
      events = BatteryEvent.order(created_at: :desc).limit(15).to_a
      rows   = BatteryReading.where("created_at > ?", 24.hours.ago).order(:created_at)
                             .pluck(:created_at, :level).map { |t, l| { x: t.iso8601, y: l } }
      ch = Turbo::StreamsChannel
      p  = "battery_automations"

      ch.broadcast_replace_to(STREAM, target: "live-automation", partial: "#{p}/automation", locals: { setting: s })
      ch.broadcast_replace_to(STREAM, target: "live-error",      partial: "#{p}/error",      locals: { setting: s })
      ch.broadcast_replace_to(STREAM, target: "live-battery",    partial: "#{p}/battery",    locals: { setting: s, latest: latest })
      ch.broadcast_replace_to(STREAM, target: "live-plug-state", partial: "#{p}/plug_state",  locals: { setting: s })
      ch.broadcast_replace_to(STREAM, target: "live-status",     partial: "#{p}/status",     locals: { setting: s })
      ch.broadcast_replace_to(STREAM, target: "live-fields",     partial: "#{p}/fields",     locals: { latest: latest })
      ch.broadcast_replace_to(STREAM, target: "live-events",     partial: "#{p}/events",     locals: { events: events })
      ch.broadcast_update_to(STREAM,  target: "chart-feed", content: rows.to_json)
    rescue StandardError => e
      Rails.logger.warn("[BatteryAutomation] broadcast failed: #{e.class}: #{e.message}")
    end
  end
end
