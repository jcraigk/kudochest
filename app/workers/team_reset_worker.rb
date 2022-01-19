# frozen_string_literal: true
class TeamResetWorker
  include Sidekiq::Worker
  sidekiq_options queue: :team_reset, lock: :until_executed

  def perform(team_id)
    team = Team.find(team_id)
    TeamResetService.call(team:)
  end
end
