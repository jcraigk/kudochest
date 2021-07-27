# frozen_string_literal: true
class WeeklyReport::TeamWorker
  include ActionView::Helpers::TextHelper
  include PointsHelper
  include Sidekiq::Worker

  sidekiq_options queue: :weekly_report

  attr_reader :team_id

  def perform(team_id)
    @team_id = team_id
    @quantity_from = {}
    @quantity_to = {}

    return unless team.weekly_report?

    send_email
  end

  private

  def send_email
    WeeklyReportMailer.team_report(team, data).deliver
  end

  def data
    OpenStruct.new(
      karma_received: points_format(karma_received),
      karma_from_streak: points_format(karma_from_streak),
      levelup_sentence: levelup_sentence,
      top_recipients: top_recipients,
      top_benefactors: top_benefactors,
      loot_claims_sentence: loot_claims_sentence
    )
  end

  def top_recipients
    recipient_quantities.reject { |data| data.quantity.zero? }.sort_by(&:quantity).reverse.take(5)
  end

  def top_benefactors
    benefactor_quantities.reject { |data| data.quantity.zero? }.sort_by(&:quantity).reverse.take(5)
  end

  def recipient_quantities
    profiles.map do |profile|
      OpenStruct.new(profile: profile, quantity: quantity_to(profile))
    end
  end

  def benefactor_quantities
    profiles.map do |profile|
      OpenStruct.new(profile: profile, quantity: quantity_from(profile))
    end
  end

  def quantity_from(profile)
    @quantity_from[profile.id] ||=
      Tip.where('tips.created_at > ?', previous_timestamp)
         .where(from_profile: profile)
         .sum(:quantity)
  end

  def quantity_to(profile)
    @quantity_to[profile.id] ||=
      Tip.where('tips.created_at > ?', previous_timestamp)
         .where(to_profile: profile)
         .sum(:quantity)
  end

  def tips_received
    @tips_received ||=
      Tip.where(to_profile_id: profiles.map(&:id))
         .where('tips.created_at > ?', previous_timestamp)
         .includes(:from_profile)
         .order(quantity: :desc)
  end

  def karma_received
    @karma_received ||= tips_received.sum(:quantity)
  end

  def karma_from_streak
    tips_received.where(source: 'streak').sum(:quantity)
  end

  def levelup_sentence
    return unless team.enable_levels?
    return 'No users leveled up' if num_levelups.zero?
    "#{pluralize(num_levelups, 'user')} leveled up!"
  end

  def num_levelups
    @num_levelups ||= profile_levelups.count { |stat| stat.delta.positive? }
  end

  def profile_levelups
    profiles.map do |profile|
      karma_received = quantity_to(profile)
      previous_level = PointsToLevelService.call(team: team, karma: profile.karma - karma_received)
      OpenStruct.new(name: profile.display_name, delta: profile.level - previous_level)
    end
  end

  def loot_claims_sentence
    claims = Claim.where('created_at > ?', previous_timestamp)
    return 'None' if claims.size.zero?
    num_pending = claims.all.count(&:pending?)
    "#{pluralize(claims.size, 'new claim')} (#{num_pending} pending fulfillment)"
  end

  def previous_timestamp
    @previous_timestamp ||= 1.week.ago
  end

  def team
    @team ||= Team.find(team_id)
  end

  def profiles
    @profiles ||= team.profiles.active
  end
end
