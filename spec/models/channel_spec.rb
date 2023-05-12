require 'rails_helper'

RSpec.describe Channel do
  subject(:channel) { build(:channel) }

  it { is_expected.to be_a(ApplicationRecord) }

  it { is_expected.to belong_to(:team) }

  it { is_expected.to validate_uniqueness_of(:rid).scoped_to(:team_id) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:team_id) }

  describe '#find_with_team' do
    subject!(:channel) { create(:channel) }

    before do
      create(:channel, rid: channel.rid, team: build(:team))
    end

    it 'returns only channel from given team' do
      expect(described_class.find_with_team(channel.team.rid, channel.rid)).to eq(channel)
    end
  end

  describe '#matching scope' do
    let!(:channel1) { create(:channel, name: 'bat-cave') }
    let!(:channel2) { create(:channel, name: 'cat-cave') }

    before do
      create(:channel, name: 'general')
      create(:channel, name: 'man')
    end

    it 'returns only matching profiles' do
      expect(described_class.matching('cave')).to contain_exactly(channel1, channel2)
    end
  end
end
