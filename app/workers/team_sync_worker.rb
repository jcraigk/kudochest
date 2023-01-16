# frozen_string_literal: true
class TeamSyncWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform(team_rid, first_run = false)
    team = Team.find_by!(rid: team_rid)
    return unless team.active?
    ConstService.call(team.plat, 'TeamSyncService').call(team:, first_run:)
  end
end
