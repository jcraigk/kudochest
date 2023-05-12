require 'rails_helper'

RSpec.describe TeamUpdateWorker do
  subject(:perform) { described_class.new.perform(team.rid, name, avatar_url) }

  let(:team) { create(:team) }
  let(:name) { 'Starry Night' }
  let(:avatar_url) { 'https://example.com/avatar.png' }

  before do
    allow(TeamUpdateService).to receive(:call)
    perform
  end

  it 'calls service with expected args' do
    expect(TeamUpdateService).to \
      have_received(:call).with(team:, name:, avatar_url:)
  end
end
