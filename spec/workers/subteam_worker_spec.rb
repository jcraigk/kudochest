# frozen_string_literal: true
require 'rails_helper'

RSpec.describe SubteamWorker do
  subject(:perform) { described_class.new.perform(team.rid) }

  let(:team) { create(:team) }

  before do
    allow(Slack::SubteamService).to receive(:call)
    perform
  end

  it 'calls service with expected args' do
    expect(Slack::SubteamService).to have_received(:call).with(team: team)
  end
end
