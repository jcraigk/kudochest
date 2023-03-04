# frozen_string_literal: true
class SubteamSyncWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_and_while_executing

  def perform(team_rid)
    team = Team.find_by!(rid: team_rid)
    return unless team.active?
    ConstService.call(team.plat, 'SubteamSyncService').call(team:)
  end
end
