module RememberSelections
  extend ActiveSupport::Concern

  attr_reader :current_profile, :current_team

  included do
    before_action :remember_owned_team
    before_action :fetch_and_remember_profile
  end

  protected

  def remember_owned_team
    return if current_user.blank? || team_from_param.blank?
    session[:team_id] = team_from_param.id
  end

  def fetch_and_remember_profile
    return if current_user.blank?

    @current_profile =
      if session[:profile_id].blank?
        default_profile
      elsif profile_from_param
        profile_from_param
      else
        profile_from_session
      end
    session[:profile_id] = @current_profile.id if @current_profile
  end

  def profile_from_session
    Profile.find_by(id: session[:profile_id])
  end

  def default_profile
    current_user.profiles.order(created_at: :desc).first
  end

  def profile_from_param
    return if params[:profile_id].blank? || params[:profile_id] == session[:profile_id]
    @profile_from_param ||= Profile.find_by(id: params[:profile_id], user_id: current_user)
  end

  def team_from_param
    return if params[:team_id].blank? || params[:team_id] == session[:team_id]
    return @current_team if @current_team
    @current_team = Team.find_by(id: params[:team_id], owning_user: current_user)
  end

  def fetch_current_team
    @current_team = (team_from_session || default_team)
  end

  def team_from_session
    return if session[:team_id].blank?
    Team.find_by(id: session[:team_id])
  end

  def default_team
    current_user.owned_teams.order(created_at: :desc).first
  end
end
