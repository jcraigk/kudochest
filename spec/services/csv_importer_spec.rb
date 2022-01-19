# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CsvImporter do
  subject(:call) { described_class.call(team:, text: csv_text) }

  let(:team) { create(:team, :with_app_profile) }
  let(:profile1) { create(:profile, team:) }
  let(:profile2) { create(:profile, team:) }
  let(:csv_text) do
    [
      [profile1.display_name, 100].join(','),
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

  it 'increases profile.points' do
    call
    expect(profile1.reload.points).to eq(100)
    expect(profile2.reload.points).to eq(250)
  end

  it 'increments priofile.points_claimed' do
    call
    expect(profile1.reload.points_claimed).to eq(100)
  end
end
