# frozen_string_literal: true
class Actions::SubteamSync < Actions::Base
  def call
    sync_subteam
  end

  private

  def sync_subteam
    SubteamSyncWorker.perform_async(params[:team_rid])
  end
end
