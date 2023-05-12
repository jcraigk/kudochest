require 'rails_helper'

RSpec.describe ChannelSyncWorker do
  subject(:perform) { described_class.new.perform(team.rid, new_channel_rid) }

  let(:team) { create(:team) }
  let(:new_channel_rid) { 'new_channel_rid' }

  before do
    allow(Team).to receive(:find_by!).with({ rid: team.rid }).and_return(team)
    allow(Slack::ChannelSyncService).to receive(:call)
    perform
  end

  it 'calls service with expected args' do
    expect(Slack::ChannelSyncService)
      .to have_received(:call).with(team:, new_channel_rid:)
  end
end
