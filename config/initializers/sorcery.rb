# frozen_string_literal: true

Rails.application.config.sorcery.submodules = %i[
  external
  remember_me
  reset_password
  user_activation
]

Rails.application.config.sorcery.configure do |config|
  config.external_providers = %i[discord facebook google slack]

  # Discord
  config.discord.callback_url = "#{App.base_url}/oauth/callback/discord"
  config.discord.key = ENV['DISCORD_CLIENT_ID']
  config.discord.secret = ENV['DISCORD_CLIENT_SECRET']
  config.discord.scope = 'email'
  config.discord.user_info_mapping = { email: 'email' }

  # Facebook
  config.facebook.key = ENV['OAUTH_FACEBOOK_KEY']
  config.facebook.secret = ENV['OAUTH_FACEBOOK_SECRET']
  config.facebook.callback_url = "#{App.base_url}/oauth/callback/facebook"
  config.facebook.user_info_path = 'me?fields=email'
  config.facebook.user_info_mapping = { email: 'email' }
  config.facebook.access_permissions = %w[email]
  config.facebook.display = 'page'
  config.facebook.api_version = 'v2.3'
  config.facebook.parse = :json

  # Google
  config.google.key = ENV['OAUTH_GOOGLE_KEY']
  config.google.secret = ENV['OAUTH_GOOGLE_SECRET']
  config.google.callback_url = "#{App.base_url}/oauth/callback/google"
  config.google.user_info_mapping = { email: 'email' }
  config.google.scope = 'https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile'

  # Slack
  config.slack.callback_url = "#{App.base_url}/oauth/callback/slack"
  config.slack.key = ENV['SLACK_CLIENT_ID']
  config.slack.secret = ENV['SLACK_CLIENT_SECRET']
  config.slack.user_info_mapping = { email: 'email' }

  config.cookie_domain = ENV['WEB_DOMAIN']

  # General auth settings
  config.user_class = 'User'
  config.user_config do |user|
    user.stretches = 1 if Rails.env.test?
    user.remember_me_token_persist_globally = true
    user.user_activation_mailer = UserMailer
    user.email_delivery_method = :deliver_later
    user.activation_needed_email_method_name = :verification_required
    user.activation_success_email_method_name = nil
    user.reset_password_mailer = UserMailer
    user.reset_password_email_method_name = :reset_password
    user.authentications_class = Authentication
  end
end
