class TeamPolicy
  attr_reader :user, :team

  def initialize(user, team)
    @user = user
    @team = team
  end

  def index?
    user_owns_team?
  end

  def edit?
    user_owns_team?
  end

  def update?
    user_owns_team?
  end

  def reset_stats?
    user_owns_team?
  end

  def join_channels?
    user_owns_team?
  end

  def export_data?
    user_owns_team?
  end

  private

  def user_owns_team?
    team.owning_user == user
  end
end
