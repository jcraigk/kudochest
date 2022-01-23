# frozen_string_literal: true
class SubteamSyncWorker
  include Sidekiq::Worker
  sidekiq_options queue: :team_sync, lock: :until_and_while_executing

  def perform(team_rid)
    team = Team.find_by!(rid: team_rid)
    return unless team.active?
    "#{team.plat}::SubteamSyncService".constantize.call(team:)
  end
end
