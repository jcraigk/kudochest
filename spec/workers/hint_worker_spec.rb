require 'rails_helper'

RSpec.describe HintWorker do
  subject(:perform) { described_class.new.perform(team.id) }

  let(:team) { create(:team, hint_frequency: 'daily') }

  before do
    allow(HintService).to receive(:call)
    perform
  end

  it 'calls service with expected args' do
    expect(HintService).to have_received(:call).with(team:)
  end
end
