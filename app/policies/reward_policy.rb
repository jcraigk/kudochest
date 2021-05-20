# frozen_string_literal: true
class RewardPolicy
  attr_reader :user, :reward

  def initialize(user, reward)
    @user = user
    @reward = reward
  end

  def index?
    user.owned_teams.any?
  end

  def new?
    user.owned_teams.any?
  end

  def create?
    user.owned_teams.any?
  end

  def edit?
    user_owns_team?
  end

  def update?
    user_owns_team?
  end

  def destroy?
    user_owns_team?
  end

  private

  def user_owns_team?
    reward.team.owning_user == user
  end
end
