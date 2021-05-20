# frozen_string_literal: true
class Discord::ChannelMemberService < Base::ChannelMemberService
  private

  def channel_members
    JSON.parse(
      Discordrb::API::Channel.messages(App.discord_token, channel_rid, 100),
      object_class: OpenStruct
    ).map(&:author).map(&:id).uniq
  end
end
