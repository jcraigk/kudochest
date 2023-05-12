class Actions::TeamRename < Actions::Base
  def call
    update_team
  end

  private

  def update_team
    TeamUpdateWorker.perform_async(params[:team_rid], params[:event][:name])
  end
end
