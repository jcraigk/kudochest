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
      num_givers:,
      points_sent:,
      num_recipients:,
      points_from_streak:,
      leveling_sentence:,
      rank_sentence:,
      top_recipients:,
      top_givers:
  end

  def num_givers
    unique_givers.size
  end

  def num_recipients
    unique_recipients.size
  end

  def unique_recipients
    @unique_recipients ||= tips_sent.map(&:to_profile).uniq
  end

  def recipient_quantities
    unique_recipients.map do |profile|
      ProfileQuantity.new(profile, quantity_to(profile))
    end
  end

  def unique_givers
    @unique_givers ||= tips_received.map(&:from_profile).uniq
  end

  def giver_quantities
    unique_givers.map do |profile|
      ProfileQuantity.new(profile, quantity_from(profile))
    end
  end

  def quantity_to(profile)
    tips_sent.select { |tip| tip.to_profile_id == profile.id }.sum(&:quantity)
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

  def tips_sent
    @tips_sent ||=
      Tip.where(from_profile: profile)
         .where('tips.created_at > ?', timeframe)
         .order(quantity: :desc)
  end

  def timeframe
    @timeframe ||= NUM_DAYS.days.ago
  end

  def points_received
    @points_received ||= tips_received.sum(:quantity)
  end

  def points_sent
    @points_sent ||= tips_sent.sum(:quantity)
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

  def previous_level
    PointsToLevelService.call(team: profile.team, points: profile.points - points_received)
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
    :profile, :points_received, :num_givers, :points_sent, :num_recipients,
    :points_from_streak, :leveling_sentence, :rank_sentence, :top_recipients, :top_givers,
    keyword_init: true
  ProfileQuantity = Struct.new(:profile, :quantity)
end
