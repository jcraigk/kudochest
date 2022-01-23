# frozen_string_literal: true
require 'rails_helper'

RSpec.describe SubteamSyncWorker do
  subject(:perform) { described_class.new.perform(team.rid) }

  let(:team) { create(:team) }

  before do
    allow(Slack::SubteamSyncService).to receive(:call)
    perform
  end

  it 'calls service with expected args' do
    expect(Slack::SubteamSyncService).to have_received(:call).with(team:)
  end
end
