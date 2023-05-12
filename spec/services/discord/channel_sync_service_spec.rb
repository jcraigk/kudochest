require 'rails_helper'

RSpec.describe Discord::ChannelSyncService, vcr: {
  cassette_name: 'discord/ChannelSyncService/fetch_channels'
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
        name: 'kudos'
      }
    ].to_json
  end
  let(:new_channel_rid) { nil }

  before do
    allow(Discordrb::API::Server)
      .to receive(:channels).with(App.discord_token, team.rid).and_return(mock_data)
  end

  # TODO: This needs to be Discord-specific (record the cassette)
  # include_examples 'ChannelSyncService'
end
