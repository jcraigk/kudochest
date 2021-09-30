# frozen_string_literal: true
class ProfileWorker
  include Sidekiq::Worker
  sidekiq_options queue: :team_sync, lock: :until_and_while_executing

  def perform(team_rid, first_run = false)
    team = Team.find_by!(rid: team_rid)
    return unless team.active?
    "#{team.plat}::ProfileService".constantize.call(team: team, first_run: first_run)
  end
end
