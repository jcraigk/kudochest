# frozen_string_literal: true
class Actions::AppHomeOpened < Actions::Base
  def call
    return if profile.welcomed_at

    mark_profile_welcomed
    respond
  end

  private

  def mark_profile_welcomed
    profile.update!(welcomed_at: Time.current)
  end

  def respond
    ChatResponse.new(mode: :direct, text:)
  end

  def text
    I18n.t \
      'profiles.app_home_opened',
      app: App.app_name,
      url: App.help_url,
      points: App.points_term
  end
end
