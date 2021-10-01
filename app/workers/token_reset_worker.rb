# frozen_string_literal: true
class TokenResetWorker
  include Sidekiq::Worker
  sidekiq_options queue: :token_reset, lock: :until_executed

  def perform(team_id)
    team = Team.find(team_id)
    return unless team.active?
    TokenResetService.call(team: team)
  end
end
