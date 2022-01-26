# frozen_string_literal: true
class Reports::TeamDigestService < Reports::BaseDigestService
  include PointsHelper

  option :team

  def call
    team_data
  end

  private

  def team_data
    TeamData.new \
      team:,
      points_sent:,
      num_givers:,
      num_recipients:,
      points_from_streak:,
      leveling_sentence:,
      top_recipients:,
      top_givers:,
      loot_claims_sentence:
  end

  def num_recipients
    tips.map(&:to_profile).uniq.size
  end

  def num_givers
    tips.map(&:from_profile).uniq.size
  end

  def recipient_quantities
    profiles.map do |profile|
      ProfileQuantity.new(profile, quantity_to(profile))
    end
  end

  def giver_quantities
    profiles.map do |profile|
      ProfileQuantity.new(profile, quantity_from(profile))
    end
  end

  def quantity_to(profile)
    tips.select { |tip| tip.to_profile_id == profile.id }.sum(&:quantity)
  end

  def quantity_from(profile)
    tips.select { |tip| tip.from_profile_id == profile.id }.sum(&:quantity)
  end

  def tips
    @tips ||=
      Tip.where(to_profile_id: profiles.map(&:id))
         .where('tips.created_at > ?', timeframe)
         .includes(:from_profile)
         .order(quantity: :desc)
  end

  def points_sent
    @points_sent ||= tips.sum(:quantity)
  end

  def points_from_streak
    tips.where(source: 'streak').sum(:quantity)
  end

  def leveling_sentence
    return unless team.enable_levels?
    return 'No users changed levels' if num_levelups.zero? && num_leveldowns.zero?
    parts = []
    parts << "#{pluralize(num_levelups, 'user')} leveled up" if num_levelups.positive?
    parts << "#{pluralize(num_leveldowns, 'user')} lost a level" if num_leveldowns.positive?
    parts.join(' and ')
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
          points: profile.points - quantity_to(profile)
      ProfileDelta.new(profile.display_name, profile.level - previous_level)
    end
  end

  def loot_claims_sentence
    return unless team.enable_loot?
    claims = Claim.where('created_at > ?', timeframe)
    return 'None' if claims.size.zero?
    num_pending = claims.all.count(&:pending?)
    "#{pluralize(claims.size, 'new claim')} (#{num_pending} pending fulfillment)"
  end

  def timeframe
    @timeframe ||= num_days.days.ago
  end

  def profiles
    @profiles ||= team.profiles.active
  end

  TeamData = Struct.new \
    :team, :points_sent, :num_givers, :num_recipients, :points_from_streak, :leveling_sentence,
    :top_recipients, :top_givers, :loot_claims_sentence, keyword_init: true
  ProfileDelta = Struct.new(:name, :delta)
  ProfileQuantity = Struct.new(:profile, :quantity)
end
