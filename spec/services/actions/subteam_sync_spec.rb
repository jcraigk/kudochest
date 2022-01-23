# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Actions::SubteamSync do
  subject(:action) { described_class.call(**params) }

  let(:team) { build(:team) }

  let(:params) { { team_rid: team.rid } }

  before do
    allow(SubteamSyncWorker).to receive(:perform_async)
  end

  it 'calls SubteamSyncWorker' do
    action
    expect(SubteamSyncWorker).to have_received(:perform_async).with(team.rid)
  end

  it 'responds silently' do
    expect(action).to eq(nil)
  end
end
