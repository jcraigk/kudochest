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
    Team.active.find_each do |team|
      current_hour = Time.use_zone(team.time_zone) { Time.current.beginning_of_hour }
      handle_hint_post(team, current_hour)
      handle_token_dispersals(team, current_hour)
    end
  end

  def handle_token_dispersals(team, current_hour)
    return if !team.throttle_tips ||
              team.token_hour != current_hour.hour ||
              team.next_tokens_at > current_hour
    TokenDispersalWorker.perform_async(team.id)
  end

  def handle_hint_post(team, current_hour)
    return if team.hint_frequency.never? ||
              team.hint_channel_rid.blank? ||
              team.next_hint_at > current_hour
    HintWorker.perform_async(team.id)
  end
end
