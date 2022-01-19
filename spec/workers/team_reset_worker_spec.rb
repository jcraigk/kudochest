# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TeamResetWorker do
  subject(:perform) { described_class.new.perform(team.id) }

  let(:team) { create(:team) }

  before do
    allow(Team).to receive(:find).with(team.id).and_return(team)
    allow(TeamResetService).to receive(:call)
    perform
  end

  it 'calls service with expected args' do
    expect(TeamResetService).to have_received(:call).with(team:)
  end
end
