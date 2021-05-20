# frozen_string_literal: true
class TeamUpdateService < Base::Service
  option :team
  option :name
  option :avatar_url

  def call
    update_team_name
    update_profile_slugs
  end

  private

  def update_team_name
    team.name = name
    team.avatar_url = avatar_url if avatar_url.present?
    team.save!
  end

  def update_profile_slugs
    team.profiles.each(&:reset_slug!)
  end
end
