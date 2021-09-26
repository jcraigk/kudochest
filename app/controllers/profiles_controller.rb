# frozen_string_literal: true
class ProfilesController < ApplicationController
  skip_before_action :require_login, only: %i[connect]

  def connect
    return redirect_to_dashboard alert: shared_admin_msg if shared_admin?
    return redirect_to_dashboard alert: invalid_token_msg if requested_profile.blank?
    return redirect_to_dashboard alert: already_connected_msg if requested_profile.user_id.present?
    return connect_profile if current_user
    redirect_to_login
  end

  def new; end

  def edit
    authorize current_profile
  end

  def update
    authorize current_profile
    return update_success if current_profile.update(profile_params)
    update_failure
  end

  def random_showcase
    fetch_showcase_profile
    @leaderboard = LeaderboardService.call(profile: @profile)
    @hide_paging = true
    render 'profiles/random_showcase', layout: false
  end

  def show
    @profile = Profile.find_by(slug: params[:id])
    redirect_to dashboard_path if @profile.blank?

    authorize @profile
    build_dashboard_for(@profile)
  end

  private

  def fetch_showcase_profile
    last_profile_id = params[:last_profile_id].to_i
    @profile = Profile.active.where(team: current_profile.team)
    @profile = @profile.where.not(id: last_profile_id) if last_profile_id.positive?
    @profile = @profile.order('RANDOM()').first
  end

  def redirect_to_login
    session[:return_to_url] = request.original_url
    redirect_to login_path, notice: t('profiles.login_to_connect')
  end

  def connect_profile
    requested_profile.update!(user: current_user)
    @current_profile = requested_profile
    session[:profile_id] = @current_profile.id
    redirect_to_dashboard notice: success_msg
  end

  def requested_profile
    @requested_profile ||= Profile.find_by(reg_token: params[:reg_token])
  end

  def redirect_to_dashboard(opts)
    redirect_to dashboard_path, opts
  end

  def success_msg
    t(
      'profiles.connect_success',
      profile: current_profile.long_name,
      team: current_profile.team.name
    )
  end

  def already_connected_msg
    t(
      'profiles.already_connected',
      profile: current_profile.long_name,
      email: current_profile.user.email
    )
  end

  def shared_admin_msg
    t('profiles.shared_admin_no_connect')
  end

  def invalid_token_msg
    t('profiles.connect_invalid')
  end

  def profile_params
    params.require(:profile).permit(:allow_dm, :weekly_report)
  end

  def update_success
    flash[:notice] = t('profiles.update_success')
    redirect_to edit_profile_path(current_profile)
  end

  def update_failure
    flash.now[:alert] = t(
      'profiles.update_fail',
      msg: current_profile.errors.full_messages.to_sentence
    )
    render :edit
  end
end
