class Reports::TeamDigestService < Reports::BaseDigestService
  include PointsHelper

  option :team

  def call
    team_data
  end

  private

  def team_data # rubocop:disable Metrics/MethodLength
    TeamData.new(
      team:,
      points_given:,
      jabs_given:,
      jab_givers:,
      jab_recipients:,
      point_givers:,
      point_recipients:,
      points_from_streak:,
      leveling_sentence:,
      top_recipients:,
      top_givers:,
      loot_claims_sentence:
    )
  end

  def point_givers
    profiles_matching(tips.reject(&:jab?).map(&:from_profile_id))
  end

  def jab_givers
    profiles_matching(tips.select(&:jab?).map(&:from_profile_id))
  end

  def point_recipients
    profiles_matching(tips.reject(&:jab?).map(&:to_profile_id))
  end

  def jab_recipients
    profiles_matching(tips.select(&:jab?).map(&:to_profile_id))
  end

  def profiles_matching(ids)
    profiles.select { |profile| profile.id.in?(ids) }
  end

  def num_recipients
    tips.map(&:to_profile_id).uniq.size
  end

  def num_givers
    tips.map(&:from_profile_id).uniq.size
  end

  def recipient_quantities
    profiles.map do |profile|
      ProfileQuantity.new(profile, points_to(profile))
    end
  end

  def giver_quantities
    profiles.map do |profile|
      ProfileQuantity.new(profile, points_from(profile))
    end
  end

  def points_to(profile)
    tips.select do |tip|
      tip.to_profile_id == profile.id && tip.quantity.positive?
    end.sum(&:quantity)
  end

  def points_from(profile)
    tips.select do |tip|
      tip.from_profile_id == profile.id && tip.quantity.positive?
    end.sum(&:quantity)
  end

  def tips
    @tips ||=
      Tip.select(:quantity, :source, :from_profile_id, :to_profile_id)
         .where(to_profile_id: profiles.map(&:id))
         .where('tips.created_at > ?', timeframe)
         .order(quantity: :desc)
         .all
  end

  def points_given
    @points_given ||= tips.reject(&:jab?).sum(&:quantity)
  end

  def jabs_given
    @jabs_given ||= tips.select(&:jab?).sum(&:quantity).abs
  end

  def points_from_streak
    tips.select { |tip| tip.source == 'streak' }.sum(&:quantity)
  end

  def leveling_sentence
    return unless team.enable_levels?
    return 'None' if num_levelups.zero? && num_leveldowns.zero?
    parts = []
    parts << num_levelups_sentence if num_levelups.positive?
    parts << num_leveldowns_sentence if num_leveldowns.positive?
    parts.join(' and ')
  end

  def num_levelups_sentence
    "#{pluralize(num_levelups, 'user')} leveled up"
  end

  def num_leveldowns_sentence
    "#{pluralize(num_leveldowns, 'user')} lost a level"
  end

  def num_levelups
    @num_levelups ||= profile_levelings.count { |stat| stat.delta.positive? }
  end

  def num_leveldowns
    @num_leveldowns ||= profile_levelings.count { |stat| stat.delta.negative? }
  end

  def profile_levelings
    profiles.map do |profile|
      previous_level =
        PointsToLevelService.call \
          team:,
          points: profile.total_points - balance_to(profile)
      ProfileDelta.new(profile.display_name, profile.level - previous_level)
    end
  end

  def balance_to(profile)
    selected_tips = tips.select { |tip| tip.to_profile_id == profile.id }
    selected_tips = selected_tips.reject(&:jab?) unless team.deduct_jabs?
    selected_tips.sum(&:quantity)
  end

  def loot_claims_sentence
    return unless team.enable_loot?
    claims = Claim.where('created_at > ?', timeframe)
    return 'None' if claims.empty?
    num_pending = claims.all.count(&:pending?)
    "#{pluralize(claims.size, 'new claim')} (#{num_pending} pending fulfillment)"
  end

  def timeframe
    @timeframe ||= num_days.days.ago
  end

  def profiles
    @profiles ||= team.profiles.active.all
  end

  TeamData = Struct.new \
    :team, :points_given, :jabs_given, :num_givers, :num_recipients, :points_from_streak,
    :point_givers, :jab_givers, :point_recipients, :jab_recipients,
    :leveling_sentence, :top_recipients, :top_givers, :loot_claims_sentence, keyword_init: true
  ProfileDelta = Struct.new(:name, :delta)
  ProfileQuantity = Struct.new(:profile, :quantity)
end
