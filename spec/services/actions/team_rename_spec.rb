# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Actions::TeamRename do
  subject(:action) { described_class.call(params) }

  let(:team) { create(:team) }
  let(:name) { 'New Name' }
  let(:curated_params) do
    {
      team_rid: team.rid
    }
  end
  let(:slack_params) do
    {
      event: {
        name: name
      }
    }
  end
  let(:params) { curated_params.merge(slack_params) }

  before do
    allow(TeamUpdateWorker).to receive(:perform_async)
  end

  it 'calls TeamUpdateWorker' do
    action
    expect(TeamUpdateWorker).to have_received(:perform_async).with(team.rid, name)
  end

  it 'responds silently' do
    expect(action).to eq(nil)
  end
end
