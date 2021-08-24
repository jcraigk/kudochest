# frozen_string_literal: true
class Slack::ChannelNameService < Base::Service
  option :team
  option :channel_rid

  UNKNOWN_CHANNEL = 'unknown'

  def call
    channel_name.presence || UNKNOWN_CHANNEL
  end

  private

  def channel_name
    team.slack_client.conversations_info(channel: channel_rid)[:channel][:name]
  rescue Slack::Web::Api::Errors::ChannelNotFound
    nil
  end
end
