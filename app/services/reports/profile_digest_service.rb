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
    profiles_matching(tips_given.map(&:to_profile_id)).map do |profile|
      ProfileQuantity.new(profile, quantity_to(profile))
    end
  end

  def point_givers
    profiles_matching(tips_received.reject(&:jab?).map(&:from_profile_id))
  end

  def jab_givers
    profiles_matching(tips_received.select(&:jab?).map(&:from_profile_id))
  end

  def point_recipients
    profiles_matching(tips_given.reject(&:jab?).map(&:to_profile_id))
  end

  def jab_recipients
    profiles_matching(tips_given.select(&:jab?).map(&:to_profile_id))
  end

  def profiles_matching(ids)
    profiles.select { |profile| profile.id.in?(ids.uniq) }
  end

  def giver_quantities
    profiles_matching(tips_received.map(&:from_profile_id)).map do |profile|
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
      Tip.select(:quantity, :source, :from_profile_id)
         .where(to_profile: profile)
         .where('tips.created_at > ?', timeframe)
         .order(quantity: :desc)
         .all
  end

  def tips_given
    @tips_given ||=
      Tip.select(:quantity, :to_profile_id)
         .where(from_profile: profile)
         .where('tips.created_at > ?', timeframe)
         .order(quantity: :desc)
         .all
  end

  def timeframe
    @timeframe ||= NUM_DAYS.days.ago.beginning_of_day
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
    tips_received.select { |tip| tip.source == 'streak' }.sum(&:quantity)
  end

  def leveling_sentence
    return unless team.enable_levels?

    delta = profile.level - previous_level
    case delta
    when 0 then "Held steady at level #{profile.level}"
    when 1 then "Gained a level - #{level_snippet}"
    when -1 then "Lost a level - #{level_snippet}"
    when 1..1_000 then "Gained #{pluralize(delta, 'level')} - #{level_snippet}"
    when -1..-1_000 then "Lost #{pluralize(delta.abs, 'level')} - #{level_snippet}"
    end
  end

  def level_snippet
    "now at #{profile.level}"
  end

  def point_deduction
    team.deduct_jabs? ? (points_received + jabs_received) : points_received
  end

  def previous_level
    PointsToLevelService.call(team:, points: profile.total_points - point_deduction)
  end

  def rank_sentence
    profile.rank
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

  # def leaderboard_data
  #   @leaderboard_data ||=
  #     LeaderboardPageService.call(
  #       profile:,
  #       previous_timestamp: timeframe,
  #       count: 1
  #     )&.profiles&.first
  # end

  def team
    @team ||= profile.team
  end

  def profiles
    @profiles ||= team.profiles.active.where(id: unique_profile_ids)
  end

  def unique_profile_ids
    (tips_received.map(&:from_profile_id) + tips_given.map(&:to_profile_id)).uniq
  end

  DigestData = Struct.new \
    :profile, :points_received, :jabs_received, :point_givers, :jab_givers,
    :points_given, :jabs_given, :point_recipients, :jab_recipients, :points_from_streak,
    :leveling_sentence, :rank_sentence, :top_recipients, :top_givers, keyword_init: true
  ProfileQuantity = Struct.new(:profile, :quantity)
end
