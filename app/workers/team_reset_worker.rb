# frozen_string_literal: true
class TeamResetWorker
  include Sidekiq::Worker
  sidekiq_options queue: :team_reset,
                  lock: :until_and_while_executing,
                  unique_args: ->(args) { [args.first] }

  def perform(team_id)
    team = Team.find(team_id)
    TeamResetService.call(team: team)
  end
end
