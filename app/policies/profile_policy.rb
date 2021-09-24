# frozen_string_literal: true
class ProfilePolicy
  attr_reader :user, :profile

  def initialize(user, profile)
    @user = user
    @profile = profile
  end

  def show?
    active_profile_on_same_team? || user_owns_team?
  end

  def edit?
    user_owns_profile?
  end

  def update?
    user_owns_profile?
  end

  private

  def user_owns_team?
    profile.team.owning_user == user
  end

  def user_owns_profile?
    profile.user == user
  end

  def active_profile_on_same_team?
    profile.user == user || active_teammate?
  end

  def active_teammate?
    profile.active? && profile.team_id.in?(user.profiles.active.map(&:team_id))
  end
end
