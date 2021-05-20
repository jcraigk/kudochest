# frozen_string_literal: true
class BonusCalculatorService < Base::Service
  option :team
  option :start_date
  option :end_date
  option :include_streak_karma
  option :include_imported_karma
  option :style
  option :pot_size
  option :karma_point_value

  def call
    @style = style.to_sym
    @profile_karma = {}

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
    ary = ['ID', 'Name', 'Karma Earned']
    ary << 'Share of Total' unless style == :karma_value
    ary << 'Bonus'
  end

  def csv_row(profile)
    karma = profile_karma(profile)
    share = share_of(karma)
    bonus = style_bonus(karma, share)
    ary = [profile.rid, profile.display_name, karma]
    ary << share_display(share) unless style == :karma_value
    ary << bonus_display(bonus)
  end

  def share_display(share)
    "#{(share * 100).round(2)}%"
  end

  def bonus_display(bonus)
    return if bonus.blank?
    format('$%<bonus>.2f', bonus: bonus)
  end

  def style_bonus(karma, share)
    case style
    when :split_pot then (pot_size * share).round(2)
    when :karma_value then (karma_point_value * karma).round(2)
    else ''
    end
  end

  def share_of(karma)
    return 0 unless karma.positive? && total_karma.positive?
    karma / total_karma.to_f
  end

  def total_karma
    @total_karma ||= active_profiles.sum { |prof| profile_karma(prof) }
  end

  def active_profiles
    @active_profiles ||= team.profiles.active.order(display_name: :asc)
  end

  def profile_karma(profile)
    @profile_karma[profile.id] ||= begin
      tips = tip_relation(profile)
      tips = tips.where.not(source: :streak) unless include_streak_karma
      tips = tips.where.not(source: :import) unless include_imported_karma
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
