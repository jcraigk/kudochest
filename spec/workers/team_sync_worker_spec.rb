require 'rails_helper'

RSpec.describe TeamSyncWorker do
  subject(:perform) { described_class.new.perform(team.rid, first_run) }

  let(:team) { create(:team) }
  let(:first_run) { true }

  before do
    allow(Slack::TeamSyncService).to receive(:call)
    perform
  end

  it 'calls service with expected args' do
    expect(Slack::TeamSyncService).to have_received(:call).with(team:, first_run:)
  end
end
