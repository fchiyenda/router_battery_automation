module BatteryAutomation
  # Summarises how the router's battery steps behaved, so the step -> percent map can be calibrated.
  class Calibration
    Row = Struct.new(:step, :percent, :count, :charging_min, :battery_min, :full_flag)
    GAP = 600 # seconds. A longer silence breaks a run, so downtime isn't counted as time on a step.

    def self.call(setting, since: 7.days.ago)
      return [] if setting.battery_scale_max >= 100
      data = BatteryReading.where("created_at > ?", since).order(:created_at).limit(20_000)
                           .pluck(:created_at, :plug_on, :raw)
      points = data.filter_map do |t, plug, raw|
        next unless raw.is_a?(Hash)
        v = raw["battery_value"].to_s
        [ t, v.to_i, plug, raw["battery_charge_full"].to_s == "1" ] if v.match?(/\A\d+\z/)
      end
      new(setting, points).rows
    end

    def initialize(setting, points)
      @setting = setting
      @points = points
    end

    def rows
      dwell = Hash.new { |h, k| h[k] = [] }
      runs.each do |r|
        next unless r[:entered] && r[:exit_at] && !r[:plug].nil? # only runs where both entry and exit were observed
        dwell[[ r[:step], r[:plug] ]] << (r[:exit_at] - r[:start]) / 60.0
      end

      (0..@setting.battery_scale_max).map do |step|
        mine = @points.select { |_, s, _, _| s == step }
        Row.new(step, @setting.percent_for(step), mine.size,
                avg(dwell[[ step, true ]]), avg(dwell[[ step, false ]]),
                mine.count { |_, _, _, full| full })
      end
    end

    private

    def runs
      out = []
      @points.each do |t, step, plug, _|
        prev = out.last
        if prev && prev[:step] == step && t - prev[:last_at] <= GAP
          prev[:last_at] = t
        else
          linked = prev && t - prev[:last_at] <= GAP
          prev[:exit_at] = t if linked
          out << { step: step, start: t, last_at: t, plug: plug, entered: linked ? true : false, exit_at: nil }
        end
      end
      out
    end

    def avg(list) = list.empty? ? nil : list.sum / list.size
  end
end
