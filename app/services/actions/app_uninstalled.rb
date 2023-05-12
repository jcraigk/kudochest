class Actions::AppUninstalled < Actions::Base
  def call
    return unless team.active?

    deactivate_team
  end

  private

  def deactivate_team
    team.update!(active: false, installed: false)
  end

  def team
    @team ||= Team.find_by(rid: params[:team_rid])
  end
end
