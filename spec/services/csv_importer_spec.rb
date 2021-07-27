# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CsvImporter do
  subject(:call) { described_class.call(team: team, text: csv_text) }

  let(:team) { create(:team, :with_app_profile) }
  let(:profile1) { create(:profile, team: team) }
  let(:profile2) { create(:profile, team: team) }
  let(:quantity1) { 100 }
  let(:csv_text) do
    [
      [profile1.display_name, quantity1].join(','),
      [profile2.display_name, 250].join(','),
      ['@invalid_name', 38].join(',')
    ].join("\n")
  end
  let(:response_text) do
    <<~TEXT.chomp
      CSV import results: 2 users updated, 1 invalid display name found: @invalid_name
    TEXT
  end

  it 'returns expected response' do
    expect(call).to eq(response_text)
  end

  it 'creates tips' do
    expect { call }.to change(Tip, :count).by(2)
  end

  it 'increases profile.karma' do
    call
    expect(profile1.reload.karma).to eq(100)
    expect(profile2.reload.karma).to eq(250)
  end

  it 'increments priofile.karma_claimed' do
    call
    expect(profile1.reload.karma_claimed).to eq(quantity1)
  end
end
