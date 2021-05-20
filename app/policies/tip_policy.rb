# frozen_string_literal: true
class TipPolicy
  attr_reader :user, :tip

  def initialize(user, tip)
    @user = user
    @tip = tip
  end

  def index?
    user.owned_teams.any?
  end

  def destroy?
    tip.from_profile.team.owning_user == user
  end
end
