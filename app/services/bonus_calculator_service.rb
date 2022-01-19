# frozen_string_literal: true
class BonusCalculatorService < Base::Service
  option :team
  option :start_date
  option :end_date
  option :include_streak_points
  option :include_imported_points
  option :style
  option :pot_size
  option :dollar_per_point

  def call
    @style = style.to_sym
    @profile_points = {}

    TeamOwnerMailer.bonus_calculator(team, csv_str).deliver_later
  end

  private

  def csv_str
    CSV.generate do |csv|
      csv << header_row
      active_profiles.each { |prof| csv << csv_row(prof) }
    end
  end

  def header_row
    ary = ['ID', 'Name', App.points_term.titleize]
    ary << 'Share of Total' unless style == :points_value
    ary << 'Bonus'
  end

  def csv_row(profile)
    points = profile_points(profile)
    share = share_of(points)
    bonus = style_bonus(points, share)
    ary = [profile.rid, profile.display_name, points]
    ary << share_display(share) unless style == :points_value
    ary << bonus_display(bonus)
  end

  def share_display(share)
    "#{(share * 100).round(2)}%"
  end

  def bonus_display(bonus)
    return if bonus.blank?
    format('$%<bonus>.2f', bonus:)
  end

  def style_bonus(points, share)
    case style
    when :split_pot then (pot_size * share).round(2)
    when :points_value then (dollar_per_point * points).round(2)
    else ''
    end
  end

  def share_of(points)
    return 0 unless points.positive? && total_points.positive?
    points / total_points.to_f
  end

  def total_points
    @total_points ||= active_profiles.sum { |prof| profile_points(prof) }
  end

  def active_profiles
    @active_profiles ||= team.profiles.active.order(display_name: :asc)
  end

  def profile_points(profile)
    @profile_points[profile.id] ||= begin
      tips = tip_relation(profile)
      tips = tips.where.not(source: :streak) unless include_streak_points
      tips = tips.where.not(source: :import) unless include_imported_points
      tips.sum(:quantity)
    end
  end

  def tip_relation(profile)
    Tip.where(to_profile: profile)
       .where(
         'created_at >= ? AND created_at <= ?',
         Time.use_zone(team.time_zone) { "#{start_date} 00:00" }.to_time.utc,
         Time.use_zone(team.time_zone) { "#{end_date} 23:59" }.to_time.utc
       )
  end
end
