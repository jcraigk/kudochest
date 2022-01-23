# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Discord::SubteamSyncService do
  let(:expected_names) { ['Test Group 3', 'Test Group 4'] }
  let(:expected_profile_rids) { %w[profile-1 profile-2] }
  let(:expected_name) { 'Test Group 4' }
  let(:new_rid) { '123' }
  let(:existing_rid) { '456' }
  let(:roles_data) do
    [
      {
        id: new_rid,
        name: 'Test Group 3',
        managed: false
      },
      {
        id: existing_rid,
        name: 'Test Group 4',
        managed: false
      },
      {
        id: '2',
        name: 'managed-role', # Should be ignored
        managed: true
      },
      {
        id: '3',
        name: '@everyone', # Always appears
        managed: false
      }
    ]
  end
  let!(:existing_subteam) do # rubocop:disable RSpec/LetSetup
    create(:subteam, :with_profiles, team:, rid: existing_rid)
  end
  let!(:old_subteam) { create(:subteam, team:) } # rubocop:disable RSpec/LetSetup

  before do
    allow(Discordrb::API::Server)
      .to receive(:roles).with(App.discord_token, team.rid).and_return(roles_data.to_json)

    expected_profile_rids.each do |profile_rid|
      create(:profile, team:, rid: profile_rid)
    end

    team.profiles.active.each do |profile|
      roles = { roles: [profile.rid.in?(expected_profile_rids) ? new_rid : nil] }
      allow(Discordrb::API::Server)
        .to receive(:resolve_member)
        .with(App.discord_token, team.rid, profile.rid)
        .and_return(roles.to_json)
    end
  end

  include_examples 'SubteamSyncService'
end
