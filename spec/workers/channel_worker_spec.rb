# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ChannelWorker do
  subject(:perform) { described_class.new.perform(team.rid, 'new_channel_rid') }

  let(:team) { create(:team) }

  before do
    allow(Team).to receive(:find_by!).with(rid: team.rid).and_return(team)
    allow(Slack::ChannelService).to receive(:call)
    perform
  end

  it 'calls service with expected args' do
    expect(Slack::ChannelService)
      .to have_received(:call).with(team:, new_channel_rid: 'new_channel_rid')
  end
end
