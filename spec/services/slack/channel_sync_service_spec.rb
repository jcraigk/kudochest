# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Slack::ChannelSyncService, vcr: { cassette_name: 'slack/channel_service' } do
  let(:new_channel_rid) { 'C0103NCM3L2' } # `bot` channel

  include_examples 'ChannelSyncService'

  it 'joins new channel' do
    expect(Slack::ChannelJoinService)
      .to have_received(:call).with(team:, channel_rid: new_channel_rid)
  end
end
