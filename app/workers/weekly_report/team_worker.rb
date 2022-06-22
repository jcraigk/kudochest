# frozen_string_literal: true
class WeeklyReport::TeamWorker
  include ActionView::Helpers::TextHelper
  include Sidekiq::Worker

  attr_reader :team_id

  def perform(team_id)
    @team_id = team_id

    return unless team.weekly_report?

    send_email
  end

  private

  def send_email
    WeeklyReportMailer.team_report(team_data).deliver
  end

  def team_data
    Reports::TeamDigestService.call(team:)
  end

  def team
    @team ||= Team.find(team_id)
  end
end
