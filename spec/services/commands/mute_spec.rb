# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Commands::Mute do
  subject(:command) { described_class.call(team_rid: team.rid, profile_rid: profile.rid) }

  let(:team) { create(:team, :with_app_profile) }
  let(:profile) { create(:profile, team: team) }

  it 'returns expected response' do
    result = command
    expect(result.mode).to eq(:private)
    expect(result.text).to include \
      ":speak_no_evil: Okay, I won't send you unsolicited direct messages"
  end

  it 'updates profile allow_unprompted_dm' do
    command
    expect(profile.reload.allow_unprompted_dm).to eq(false)
  end
end
