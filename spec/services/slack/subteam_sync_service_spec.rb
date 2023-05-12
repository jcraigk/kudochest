require 'rails_helper'

RSpec.describe Slack::SubteamSyncService, vcr: { cassette_name: 'slack/subteam_service' } do
  let(:expected_names) { ['Test Group 1', 'Test Group 2', 'Test Group 3'] }
  let(:expected_name) { 'Test Group 3' }
  let(:expected_profile_rids) { %w[UL5H1BQTG ULTHYD4UQ UNNQ4U048] }
  let!(:existing_subteam) do # rubocop:disable RSpec/LetSetup
    create(:subteam, :with_profiles, team:, handle: 'old-handle', rid: 'existing-rid')
  end
  let!(:old_subteam) { create(:subteam, team:) } # rubocop:disable RSpec/LetSetup

  before do
    allow(App).to receive(:slack_app_id).and_return('slack-app-id')
    expected_profile_rids.each { |rid| create(:profile, team:, rid:) }
  end

  include_examples 'SubteamSyncService'
end
