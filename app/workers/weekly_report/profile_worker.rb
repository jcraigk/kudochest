# frozen_string_literal: true
class WeeklyReport::ProfileWorker
  include ActionView::Helpers::TextHelper
  include PointsHelper
  include Sidekiq::Worker

  sidekiq_options queue: :default

  TIMEFRAME = 1.week.freeze
  TEAM_CACHE_TTL = 10.minutes

  attr_reader :profile_id

  def perform(profile_id)
    @profile_id = profile_id

    return unless profile.user&.email.present? && profile.weekly_report?

    send_email
  end

  private

  def send_email
    WeeklyReportMailer.profile_report(profile_data, team_data).deliver
  end

  def profile_data
    Reports::ProfileDigestService.call(profile:)
  end

  def team_data
    Rails.cache.fetch(
      "weekly_report/#{profile.team.id}",
      expires_in: TEAM_CACHE_TTL.from_now
    ) do
      Reports::TeamDigestService.call(team: profile.team)
    end
  end

  def profile
    @profile ||= Profile.includes(:team, :user).find(profile_id)
  end
end
