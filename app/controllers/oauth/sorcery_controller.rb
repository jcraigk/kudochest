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
    Honeybadger.notify(e) if defined?(Honeybadger)
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

# TODO: PR this upstream at https://github.com/Sorcery/sorcery
# The problem is that we already have the email/uid in the initial response,
# no need to request https://api.slack.com/methods/users.identity in that case,
# which was failing
# We should add a check for success on users.identity and handle errors more gracefully
class Sorcery::Providers::Slack
  def get_user_hash(access_token)
    auth_hash(access_token).tap do |h|
      h[:user_info] = access_token['user']
      h[:uid] = access_token['user']['id']
    end
  end
end
