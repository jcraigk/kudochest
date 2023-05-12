require 'rails_helper'

RSpec.describe Discord::ChannelMemberService do
  let(:channels_data) do
    team.profiles.map { |profile| { author: { id: profile.rid } } }.to_json
  end

  before do
    allow(Discordrb::API::Channel)
      .to receive(:messages).with(App.discord_token, channel.rid, 100).and_return(channels_data)
  end

  include_examples 'ChannelMemberService'
end
