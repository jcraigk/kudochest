# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Discord::ChannelService, vcr: {
  cassette_name: 'discord/ChannelService/fetch_channels'
} do
  let(:mock_data) do
    [
      {
        type: 1,
        id: '1',
        name: 'wrong-type'
      },
      {
        type: 0,
        id: '2',
        name: 'bot'
      },
      {
        type: 0,
        id: 'existing-rid',
        name: 'existing'
      },
      {
        type: 0,
        id: '3',
        name: 'general'
      },
      {
        type: 0,
        id: '4',
        name: 'karma'
      }
    ].to_json
  end
  let(:new_channel_rid) { nil }

  before do
    allow(Discordrb::API::Server)
      .to receive(:channels).with(App.discord_token, team.rid).and_return(mock_data)
  end

  include_examples 'ChannelService'
end
