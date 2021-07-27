# frozen_string_literal: true
class WeeklyReport::ProfileWorker
  include ActionView::Helpers::TextHelper
  include PointsHelper
  include Sidekiq::Worker

  sidekiq_options queue: :weekly_report

  attr_reader :profile_id

  def perform(profile_id)
    @profile_id = profile_id

    return unless profile.user&.email.present? && profile.weekly_report?

    send_email
  end

  private

  def send_email
    WeeklyReportMailer.profile_report(profile, data).deliver
  end

  def data
    OpenStruct.new(
      karma_received: points_format(karma_received),
      karma_sent: points_format(karma_sent),
      karma_from_streak: points_format(karma_from_streak),
      levelup_sentence: levelup_sentence,
      rank_sentence: rank_sentence,
      top_recipients: top_recipients,
      top_benefactors: top_benefactors
    )
  end

  def top_recipients
    tips_sent.map(&:to_profile).uniq.take(3)
  end

  def top_benefactors
    tips_received.map(&:from_profile).uniq.take(3)
  end

  def tips_received
    @tips_received ||=
      Tip.where(to_profile: profile)
         .where('tips.created_at > ?', previous_timestamp)
         .includes(:from_profile)
         .order(quantity: :desc)
  end

  def tips_sent
    @tips_sent ||=
      Tip.where(from_profile: profile)
         .where('tips.created_at > ?', previous_timestamp)
         .order(quantity: :desc)
  end

  def karma_received
    @karma_received ||= tips_received.sum(:quantity)
  end

  def karma_sent
    @karma_sent ||= tips_sent.sum(:quantity)
  end

  def karma_from_streak
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
    KarmaToLevelService.call(team: profile.team, karma: profile.karma - karma_received)
  end

  def rank_sentence
    return if leaderboard_data.blank?
    previous_rank = leaderboard_data.previous_rank
    delta = previous_rank.zero? ? 0 : leaderboard_data.rank - previous_rank
    verb = delta.positive? ? 'lost' : 'gained'
    diff = delta.abs
    case diff
    when 0 then "You held steady at ##{profile.rank}."
    when 1 then "You #{verb} a rank! #{rank_snippet}"
    else "You #{verb} #{pluralize(diff, 'rank')}! #{rank_snippet}"
    end
  end

  def rank_snippet
    "You're now at ##{profile.rank}."
  end

  def leaderboard_data
    @leaderboard_data ||=
      LeaderboardService.call(
        profile: profile,
        previous_timestamp: previous_timestamp,
        count: 1
      ).profiles.first
  end

  def previous_timestamp
    @previous_timestamp ||= 1.week.ago
  end

  def profile
    @profile ||= Profile.includes(:team, :user).find(profile_id)
  end

  def team
    @team ||= profile.team
  end
end
