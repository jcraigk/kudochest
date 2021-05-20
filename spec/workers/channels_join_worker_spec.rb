# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ChannelsJoinWorker do
  subject(:perform) { described_class.new.perform(team.id) }

  let(:team) { create(:team) }
  let!(:channels) { create_list(:channel, 2, team: team) }

  before do
    allow(Team).to receive(:find).with(team.id).and_return(team)
    allow(Slack::ChannelJoinService).to receive(:call)
    perform
  end

  it 'calls service with expected args' do
    channels.each do |channel|
      expect(Slack::ChannelJoinService)
        .to have_received(:call).with(team: team, channel_rid: channel.rid)
    end
  end
end
