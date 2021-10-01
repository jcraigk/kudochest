# frozen_string_literal: true
class ChannelsJoinWorker
  include Sidekiq::Worker
  sidekiq_options queue: :presence, lock: :until_executed

  attr_reader :team_id

  def perform(team_id)
    @team_id = team_id
    return unless team.active? && team.platform.slack?
    join_all_channels
  end

  private

  def join_all_channels
    team.channels.each do |channel|
      Slack::ChannelJoinService.call(team: team, channel_rid: channel.rid)
    end
  end

  def team
    @team ||= Team.find(team_id)
  end
end
