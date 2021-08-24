# frozen_string_literal: true
class Slack::ChannelMemberService < Base::ChannelMemberService
  private

  def channel_members
    team.slack_client.conversations_members(channel: channel_rid)[:members]
  rescue Slack::Web::Api::Errors::ChannelNotFound # App has insufficient privileges
    []
  end
end
