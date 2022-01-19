# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TeamUpdateService do
  subject(:service) { described_class.call(team:, name:, avatar_url:) }

  let(:profile) { create(:profile, display_name: 'Andy') }
  let(:team) { create(:team, profiles: [profile]) }
  let(:name) { 'Awesome Team' }
  let(:avatar_url) { 'https://example.com/avatar.png' }

  before { service }

  it 'updates the team name' do
    team.reload
    expect(team.name).to eq(name)
    expect(team.avatar_url).to eq(avatar_url)
  end

  it 'updates profile slug' do
    expect(profile.slug).to eq('awesome-team-andy')
  end
end
