# frozen_string_literal: true
class Leaderboard::RecurrentWorker
  include Sidekiq::Worker
  sidekiq_options queue: :leaderboard

  def perform
    run_team_refresh_jobs
  end

  private

  def run_team_refresh_jobs
    Team.active.find_each do |team|
      next if skip?(team)
      Leaderboard::TeamRefreshWorker.perform_async(team.id)
      Leaderboard::TeamRefreshWorker.perform_async(team.id, true)
    end
  end

  def skip?(team)
    team.last_tip_sent_at.blank? ||
      team.last_tip_sent_at <= leaderboard_refreshed_at(team)
  end

  def leaderboard_refreshed_at(team)
    Time.at(Cache::Leaderboard.new(team.id).get&.updated_at || 1).utc
  end
end
