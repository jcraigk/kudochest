# frozen_string_literal: true
class Actions::UserChange < Actions::Base
  def call
    return if irrelevant?
    update_profile
  end

  private

  def update_profile
    profile&.update!(profile_attrs)
  end

  def profile
    @profile ||= Profile.find_with_team(params[:team_rid], user_params[:id])
  end

  def profile_attrs
    {
      display_name: display_name,
      real_name: real_name,
      title: profile_params[:title],
      deleted: user_params[:deleted],
      avatar_url: profile_params[:image_512]
    }
  end

  def display_name
    profile_params[:display_name_normalized].presence || real_name
  end

  def real_name
    profile_params[:real_name_normalized]
  end

  # Slack sends `user_change` events for bots and
  # outdated/external users, so we ignore those
  def irrelevant?
    user_params[:is_restricted] == true ||
      user_params[:is_ultra_restricted] == true ||
      user_params[:is_bot] == true ||
      user_params.dig(:profile, :team) != team.rid
  end

  def profile_params
    @profile_params ||= user_params[:profile]
  end

  def user_params
    @user_params ||= params[:event][:user]
  end
end
