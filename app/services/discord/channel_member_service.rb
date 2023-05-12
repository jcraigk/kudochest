class Discord::ChannelMemberService < Base::ChannelMemberService
  private

  # TODO: Add `@here` support if feasible
  def channel_members
    JSON.parse(
      Discordrb::API::Channel.messages(App.discord_token, channel_rid, 100),
      symbolize_names: true
    ).pluck(:author).pluck(:id).uniq
  end
end
