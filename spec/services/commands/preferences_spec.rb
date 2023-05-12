require 'rails_helper'

RSpec.describe Commands::Preferences do
  subject(:command) { described_class.call(team_rid: team.rid, profile_rid: profile.rid) }

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team:) }
  let(:response) { ChatResponse.new(mode: :prefs_modal) }

  it 'returns stats text' do
    expect(command).to eq(response)
  end

  context 'when Discord' do
    before do
      team.update(platform: :discord)
      allow(Commands::Admin).to receive(:call)
      command
    end

    it 'calls Commands::Admin' do
      expect(Commands::Admin).to \
        have_received(:call).with(team_rid: team.rid, profile_rid: profile.rid)
    end
  end
end
