# frozen_string_literal: true
require 'rails_helper'

RSpec.shared_examples 'SubteamService' do
  subject(:service) { described_class.call(team:) }

  let(:team) { create(:team, api_key: 'api-key') }

  before { service }

  it 'creates subteams' do
    names = team.subteams.all.sort_by(&:name).map(&:name)
    expect(names).to eq(expected_names)
  end

  # Discord one isn't stubbed right for this, but it does work
  it 'adds members to newly created subteam' do
    subteam_profile_rids =
      Subteam.find_by(name: expected_names.first).profiles.map(&:rid).sort
    expect(subteam_profile_rids).to eq(expected_profile_rids)
  end

  it 'updates existing subteam attrs and members' do
    existing_subteam.reload
    expect(existing_subteam.name).to eq(expected_name)
    expect(existing_subteam.profiles).to eq([])
  end

  it 'destroys old teams' do
    expect { old_subteam.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
