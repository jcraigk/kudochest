# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Commands::Help do
  subject(:command) { described_class.call(team_rid: team.rid, profile_rid: profile.rid) }

  let(:team) { create(:team, :with_app_profile) }
  let(:profile) { create(:profile, team:) }

  it 'returns help text' do
    result = command
    expect(result.mode).to eq(:private)
    expect(result.text).to include("Giving #{App.points_term}:")
  end
end
