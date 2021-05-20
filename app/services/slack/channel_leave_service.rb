# frozen_string_literal: true
class Slack::ChannelLeaveService < Base::Service
  option :team
  option :channel_rid
  option :channel_name # TODO: Remove after debugging

  def call
    leave_channel
  end

  private

  def leave_channel
    team.slack_client.conversations_leave(channel: channel_rid)
  end
end
