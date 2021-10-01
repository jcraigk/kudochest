# frozen_string_literal: true
class SubteamWorker
  include Sidekiq::Worker
  sidekiq_options queue: :team_sync, lock: :until_executed

  def perform(team_rid)
    team = Team.find_by!(rid: team_rid)
    return unless team.active?
    "#{team.plat}::SubteamService".constantize.call(team: team)
  end
end
