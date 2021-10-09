# frozen_string_literal: true
class Reports::ProfileDigestService < Reports::BaseDigestService
  include PointsHelper

  option :profile

  def call
    profile_data
  end

  private

  def profile_data
    OpenStruct.new(
      profile: profile,
      points_received: points_format(points_received),
      points_sent: points_format(points_sent),
      points_from_streak: points_format(points_from_streak),
      levelup_sentence: levelup_sentence,
      rank_sentence: rank_sentence,
      top_recipients: top_recipients,
      top_benefactors: top_benefactors
    )
  end

  def recipient_quantities
    tips_sent.map(&:to_profile).uniq.map do |profile|
      OpenStruct.new(profile: profile, quantity: quantity_to(profile))
    end
  end

  def benefactor_quantities
    tips_received.map(&:from_profile).uniq.map do |profile|
      OpenStruct.new(profile: profile, quantity: quantity_from(profile))
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

  def levelup_sentence
    return unless team.enable_levels?

    delta = profile.level - previous_level
    case delta
    when 0 then "You held steady at level #{profile.level}"
    when 1 then "You gained a level! #{level_snippet}"
    else "You gained #{pluralize(delta, 'level')}! #{level_snippet}"
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
    # TODO: re-enable
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
        profile: profile,
        previous_timestamp: timeframe,
        count: 1
      )&.profiles&.first
  end

  def team
    @team ||= profile.team
  end
end
