class Actions::TeamJoin < Actions::Base
  def call
    sync_team_profiles
  end

  private

  def sync_team_profiles
    TeamSyncWorker.perform_async(params[:team_rid])
  end
end
