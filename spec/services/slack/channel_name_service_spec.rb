# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Slack::ChannelNameService do
  subject(:service) { described_class.call(team:, channel_rid: channel.rid) }

  let(:team) { create(:team, :with_profiles) }
  let(:channel) { create(:channel) }
  let(:slack_client) { instance_spy(Slack::Web::Client) }
  let(:channel_data) { { channel: { name: channel.name } } }

  before do
    allow(Slack::Web::Client).to receive(:new).and_return(slack_client)
    allow(slack_client).to receive(:conversations_info).and_return(channel_data)
  end

  it 'returns the channel name' do
    expect(service).to eq(channel.name)
  end
end
