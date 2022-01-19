# frozen_string_literal: true
require 'rails_helper'

RSpec.shared_examples 'ChannelService' do
  subject(:service) { described_class.call(team:, new_channel_rid:) }

  let(:team) { create(:team, api_key: 'api-key', join_channels: true) }
  let!(:existing_channel) { create(:channel, team:, rid: 'existing-rid') }
  let!(:archived_channel) { create(:channel, team:) }
  let(:expected_channel_names) { %w[bot existing general kudos] }
  let(:team_channel_names) { team.reload.channels.order(name: :asc).map(&:name) }

  before do
    allow(Slack::ChannelJoinService).to receive(:call)
    service
  end

  it 'creates new channels' do
    expect(team_channel_names).to eq(expected_channel_names)
  end

  it 'updates existing channels' do
    expect(existing_channel.reload.name).to eq('existing')
  end

  it 'destroys archived channels' do
    expect { archived_channel.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
