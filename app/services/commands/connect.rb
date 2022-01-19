# frozen_string_literal: true
class Commands::Connect < Commands::Base
  attr_reader :requested_profile

  def call
    connect_profile
    respond
  end

  private

  def connect_profile
    @requested_profile = Profile.find_with_team(team_rid, profile_rid)
  end

  def respond
    return respond_failure(already_connected) if requested_profile.user_id.present?
    return respond_privately(generic_connect_msg) if text.blank?
    return respond_failure(invalid_token) if user.blank?
    connect_by_token
  end

  def generic_connect_msg
    I18n.t('profiles.to_connect', team: team.name, url: connect_url)
  end

  def invalid_token
    I18n.t('profiles.connect_invalid')
  end

  def already_connected
    I18n.t('profiles.already_connected', email: requested_profile.user.email)
  end

  def user
    @user ||= User.find_by(reg_token: text)
  end

  def connect_by_token
    profile.update!(user:)
    user.reset_reg_token!
    respond_privately \
      I18n.t('profiles.connect_success_email', profile: profile.link, email: user.email)
  end

  def connect_url
    <<~TEXT.chomp
      <#{App.base_url}#{Rails.application.routes.url_helpers.profile_connection_path(reg_token: profile.reg_token)}>
    TEXT
  end
end
