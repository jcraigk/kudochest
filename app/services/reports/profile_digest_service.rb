# frozen_string_literal: true
class Reports::ProfileDigestService < Reports::BaseDigestService
  include PointsHelper

  option :profile

  def call
    profile_data
  end

  private

  def profile_data # rubocop:disable Metrics/MethodLength
    DigestData.new \
      profile:,
      points_received:,
      point_givers:,
      jabs_received:,
      jab_givers:,
      points_given:,
      point_recipients:,
      jabs_given:,
      jab_recipients:,
      points_from_streak:,
      leveling_sentence:,
      rank_sentence:,
      top_recipients:,
      top_givers:
  end

  def recipient_quantities
    unique_recipients.map do |profile|
      ProfileQuantity.new(profile, quantity_to(profile))
    end
  end

  def unique_recipients
    @unique_recipients ||= tips_given.map(&:to_profile).uniq
  end

  def point_givers
    @point_givers ||= tips_received.reject(&:jab?).map(&:from_profile).uniq
  end

  def jab_givers
    @jab_givers ||= tips_received.select(&:jab?).map(&:from_profile).uniq
  end

  def point_recipients
    @point_recipients ||= tips_received.reject(&:jab?).map(&:to_profile).uniq
  end

  def jab_recipients
    @jab_recipients ||= tips_received.select(&:jab?).map(&:to_profile).uniq
  end

  def giver_quantities
    tips_received.map(&:from_profile).uniq.map do |profile|
      ProfileQuantity.new(profile, quantity_from(profile))
    end
  end

  def quantity_to(profile)
    tips_given.select { |tip| tip.to_profile_id == profile.id }.sum(&:quantity)
  end

  def quantity_from(profile)
    tips_received.select { |tip| tip.from_profile_id == profile.id }.sum(&:quantity)
  end

  def tips_received
    @tips_received ||=
      Tip.where(to_profile: profile)
         .where('tips.created_at > ?', timeframe)
         .includes(:from_profile)
         .order(quantity: :desc)
  end

  def tips_given
    @tips_given ||=
      Tip.where(from_profile: profile)
         .where('tips.created_at > ?', timeframe)
         .order(quantity: :desc)
  end

  def timeframe
    @timeframe ||= NUM_DAYS.days.ago
  end

  def points_received
    @points_received ||= tips_received.reject(&:jab?).sum(&:quantity)
  end

  def points_given
    @points_given ||= tips_given.reject(&:jab?).sum(&:quantity)
  end

  def jabs_received
    @jabs_received ||= tips_received.select(&:jab?).sum(&:quantity).abs
  end

  def jabs_given
    @jabs_given ||= tips_given.select(&:jab?).sum(&:quantity).abs
  end

  def points_from_streak
    return unless team.enable_streaks?
    tips_received.where(source: 'streak').sum(:quantity)
  end

  def leveling_sentence
    return unless team.enable_levels?

    delta = profile.level - previous_level
    case delta
    when 0 then "You held steady at level #{profile.level}"
    when 1 then "You gained a level! #{level_snippet}"
    when -1 then "You lost a level! #{level_snippet}"
    when 1..1_000 then "You gained #{pluralize(delta, 'level')}! #{level_snippet}"
    when -1..-1_000 then "You lost #{pluralize(delta.abs, 'level')}! #{level_snippet}"
    end
  end

  def level_snippet
    "You're now at level #{profile.level}."
  end

  def point_deduction
    team.deduct_jabs? ? (points_received + jabs_received) : points_received
  end

  def previous_level
    PointsToLevelService.call(team:, points: profile.total_points - point_deduction)
  end

  def rank_sentence
    return if leaderboard_data.blank?
    rank_snippet
    # TODO: re-enable rank trends
    # previous_rank = leaderboard_data.previous_rank
    # delta = previous_rank.zero? ? 0 : leaderboard_data.rank - previous_rank
    # verb = delta.positive? ? 'lost' : 'gained'
    # diff = delta.abs
    # case diff
    # when 0 then "You held steady at ##{profile.rank}."
    # when 1 then "You #{verb} a rank! #{rank_snippet}"
    # else "You #{verb} #{pluralize(diff, 'rank')}! #{rank_snippet}"
    # end
  end

  def rank_snippet
    "You're now at ##{profile.rank}."
  end

  def leaderboard_data
    @leaderboard_data ||=
      LeaderboardService.call(
        profile:,
        previous_timestamp: timeframe,
        count: 1
      )&.profiles&.first
  end

  def team
    @team ||= profile.team
  end

  DigestData = Struct.new \
    :profile, :points_received, :jabs_received, :point_givers, :jab_givers,
    :points_given, :jabs_given, :point_recipients, :jab_recipients, :points_from_streak,
    :leveling_sentence, :rank_sentence, :top_recipients, :top_givers, keyword_init: true
  ProfileQuantity = Struct.new(:profile, :quantity)
end
