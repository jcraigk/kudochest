# frozen_string_literal: true
class ProfileWorker
  include Sidekiq::Worker
  sidekiq_options queue: :team_sync, lock: :until_executed

  def perform(team_rid, first_run = false)
    team = Team.find_by!(rid: team_rid)
    return unless team.active?
    "#{team.plat}::ProfileService".constantize.call(team:, first_run:)
  end
end
