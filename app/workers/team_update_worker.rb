# frozen_string_literal: true
class TeamUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :team_rename

  def perform(team_rid, name, avatar_url = nil)
    team = Team.find_by!(rid: team_rid)
    return unless team.active?
    TeamUpdateService.call(team:, name:, avatar_url:)
  end
end
