# frozen_string_literal: true
class Oauth::SorceryController < ApplicationController
  skip_before_action :require_login, raise: false

  def oauth
    login_at(params[:provider])
  end

  def callback
    return redirect_back_or_to(dashboard_path) if login_from(params[:provider])
    create_user_and_login
  rescue StandardError => e
    Raven.capture_exception(e) unless e.is_a?(OAuth2::Error) # Facebook failed/canceled login
    redirect_to login_path, alert: t('auth.external_fail', provider: provider_title)
  end

  private

  def create_user_and_login
    user = create_from(params[:provider])
    user.activate!
    reset_session
    auto_login(user)

    redirect_back_or_to(dashboard_path, notice: success_notice)
  rescue ActiveRecord::RecordNotUnique
    redirect_to login_path, alert: t('auth.email_taken', provider: provider_title)
  end

  def success_notice
    t('auth.external_success', provider: provider_title)
  end

  def auth_params
    params.permit(:code)
  end

  def provider_title
    params[:provider].titleize
  end
end
