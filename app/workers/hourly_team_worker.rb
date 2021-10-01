# frozen_string_literal: true
class HourlyTeamWorker
  include Sidekiq::Worker
  sidekiq_options queue: :hourly, lock: :until_executed

  attr_reader :processed_teams

  def perform
    handle_dispersals
  end

  private

  def handle_dispersals
    Team.active.where(throttle_tips: true).find_each do |team|
      current_interval = current_interval_for(team)
      next if team.token_hour != current_interval.hour
      next if next_dispersal_at(team) > current_interval
      TokenDispersalWorker.perform_async(team.id)
    end
  end

  def current_interval_for(team)
    Time.use_zone(team.time_zone) { Time.current.beginning_of_hour }
  end

  def next_dispersal_at(team)
    NextIntervalService.call(
      team: team,
      attribute: :token_frequency,
      start_at: team.tokens_disbursed_at
    )
  end
end
