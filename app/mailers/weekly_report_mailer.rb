# frozen_string_literal: true
class WeeklyReportMailer < ApplicationMailer
  helper ActionView::Helpers::UrlHelper
  helper ProfileHelper
  helper PointsHelper

  layout 'email'

  def profile_report(profile, data)
    @profile = profile
    @data = data
    email = profile.user.email
    @unsub_token = Rails.application.message_verifier(:unsubscribe).generate(email)
    @footer_gif = random_footer_gif
    mail to: email, subject: t('weekly_report.profile_subject')
  end

  def team_report(team, data)
    @team = team
    @data = data
    email = team.owning_user.email
    @unsub_token = Rails.application.message_verifier(:unsubscribe).generate(email)
    @footer_gif = random_footer_gif
    mail to: email, subject: t('weekly_report.team_subject')
  end

  private

  def random_footer_gif
    "media/images/gifs/#{GIFS['48'].sample}.gif"
  end
end
