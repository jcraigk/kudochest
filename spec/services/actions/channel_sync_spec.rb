# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Actions::ChannelSync do
  subject(:action) { described_class.call(**params) }

  let(:params) do
    {
      team_rid: team.rid,
      event_params: {
        event: {
          type: 'channel_created',
          channel: {
            id: 'new_channel_rid'
          }
        }
      }
    }
  end
  let(:team) { build(:team) }

  before do
    allow(ChannelWorker).to receive(:perform_async)
  end

  it 'calls ChannelWorker' do
    action
    expect(ChannelWorker).to have_received(:perform_async).with(team.rid, 'new_channel_rid')
  end

  it 'responds silently' do
    expect(action).to eq(nil)
  end
end
