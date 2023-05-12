class WeeklyReportMailer < ApplicationMailer
  helper ActionView::Helpers::UrlHelper
  helper PointsHelper
  helper MailHelper

  layout 'email'

  def profile_report(profile_data, team_data)
    @profile = profile_data.profile
    @profile_data = profile_data
    @team = team_data.team
    @team_data = team_data
    email = @profile.user.email
    assign_unsub_token(email)

    mail to: email, subject: t('weekly_report.profile_subject')
  end

  def team_report(team_data)
    @team = team_data.team
    @team_data = team_data
    email = @team.owning_user.email
    assign_unsub_token(email)

    mail to: email, subject: t('weekly_report.team_subject')
  end

  private

  def assign_unsub_token(email)
    @unsub_token = Rails.application.message_verifier(:unsubscribe).generate(email)
  end
end
