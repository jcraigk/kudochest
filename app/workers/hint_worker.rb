class HintWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform(team_id)
    team = Team.find(team_id)
    return unless team.active? && !team.hint_frequency.never?
    HintService.call(team:)
  end
end
