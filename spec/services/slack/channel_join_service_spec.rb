# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Slack::ChannelJoinService do
  subject(:service) { described_class.call(team:, channel_rid: channel.rid) }

  let(:team) { create(:team) }
  let(:channel) { create(:channel, team:) }
  let(:slack_client) { instance_spy(Slack::Web::Client) }

  before do
    allow(Slack::Web::Client).to receive(:new).and_return(slack_client)
    service
  end

  it 'calls #conversations.join' do
    expect(slack_client).to have_received(:conversations_join).with(channel: channel.rid)
  end
end
