# frozen_string_literal: true
class TokenDispersalWorker
  include Sidekiq::Worker
  sidekiq_options queue: :token_dispersal, lock: :until_executed

  def perform(team_id)
    team = Team.find(team_id)
    return unless team.active? && team.throttle_tips?
    TokenDispersalService.call(team:)
  end
end
