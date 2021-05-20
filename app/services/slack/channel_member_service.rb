# frozen_string_literal: true
class Slack::ChannelMemberService < Base::ChannelMemberService
  private

  def channel_members
    team.slack_client.conversations_info(channel: channel_rid)[:channel][:members]
  end
end
