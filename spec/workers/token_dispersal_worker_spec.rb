# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TokenDispersalWorker do
  subject(:perform) { described_class.new.perform(team.id) }

  let(:team) { create(:team, limit_karma: true) }

  before do
    allow(Team).to receive(:find).with(team.id).and_return(team)
    allow(TokenDispersalService).to receive(:call)
    perform
  end

  it 'calls TokenDispersalService' do
    expect(TokenDispersalService).to have_received(:call).with(team: team)
  end
end
