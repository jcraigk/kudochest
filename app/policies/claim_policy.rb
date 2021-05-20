# frozen_string_literal: true
class ClaimPolicy
  attr_reader :user, :claim

  def initialize(user, claim)
    @user = user
    @claim = claim
  end

  def index?
    user.owned_teams.any?
  end

  def edit?
    user_owns_team?
  end

  def update?
    user_owns_team?
  end

  def destroy?
    claim.fulfilled_at.blank? && (user_owns_team? || user_owns_claim?)
  end

  def show?
    user_owns_claim? || user_owns_team?
  end

  private

  def user_owns_team?
    claim.reward.team.owning_user == user
  end

  def user_owns_claim?
    claim.profile_id.in?(user.profiles.ids)
  end
end
