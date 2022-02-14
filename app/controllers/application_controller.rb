# frozen_string_literal: true
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include RememberSelections

  protect_from_forgery

  before_action :require_login, except: %i[not_authenticated]
  rescue_from Pundit::NotAuthorizedError, with: :not_authorized

  protected

  def shared_admin?
    App.shared_admin && current_user&.owned_teams&.any?
  end

  def not_authenticated
    redirect_to main_app.login_path, alert: t('auth.login_required')
  end

  def not_authorized
    flash[:alert] = t('auth.not_authorized')
    redirect_to(request.referer || dashboard_path)
  end

  def fetch_recent_tips(profile)
    received_tips(profile)
      .or(sent_tips(profile))
      .where('created_at >= ?', 100.days.ago)
      .includes(:to_profile, :from_profile, :topic)
      .order(created_at: :desc)
      .page(params[:page] || 1)
  end

  def received_tips(profile)
    Tip.where(to_profile: profile)
  end

  def sent_tips(profile)
    Tip.where(from_profile: profile)
  end

  def build_dashboard_for(profile)
    @leaderboard = LeaderboardPageService.call(profile:)
    @tips = fetch_recent_tips(profile)
    @histogram_data = TipHistogramService.call \
      profile:,
      limit: params[:limit],
      user: current_user
  end

  def email_domain_allowed?(email)
    App.user_email_domains.none? || email.split('@').last.in?(App.user_email_domains)
  end
end
