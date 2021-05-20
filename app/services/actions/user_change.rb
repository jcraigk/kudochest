# frozen_string_literal: true
class Actions::UserChange < Actions::Base
  def call
    return if irrelevant?
    update_profile
  end

  private

  def update_profile
    Profile.find_with_team(params[:team_rid], user[:id]).update!(profile_attrs)
  end

  def profile_attrs
    {
      display_name: display_name,
      real_name: real_name,
      title: profile[:title],
      deleted: user[:deleted],
      avatar_url: profile[:image_512]
    }
  end

  def display_name
    profile[:display_name_normalized].presence || real_name
  end

  def real_name
    profile[:real_name_normalized]
  end

  def irrelevant?
    user[:is_restricted] == true ||
      user[:is_ultra_restricted] == true ||
      user[:is_bot] == true
  end

  def profile
    @profile ||= user[:profile]
  end

  def user
    @user ||= params[:event][:user]
  end
end
