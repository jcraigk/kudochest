module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_profile_team

    def connect
      self.current_profile_team = find_current_profile_team
    end

    private

    def find_current_profile_team
      current_profile_team || reject_unauthorized_connection
    end

    def session
      key = Rails.application.config.session_options.fetch(:key)
      cookies.encrypted[key]&.symbolize_keys || {}
    end

    def current_profile_team
      Profile.includes(:team).find_by(id: session[:profile_id]).team
    end
  end
end
