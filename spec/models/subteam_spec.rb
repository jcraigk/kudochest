require 'rails_helper'

RSpec.describe Subteam do
  subject(:subteam) { build(:subteam) }

  it { is_expected.to be_a(ApplicationRecord) }

  it { is_expected.to belong_to(:team) }
  it { is_expected.to have_many(:subteam_memberships) }
  it { is_expected.to have_many(:profiles).through(:subteam_memberships).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:rid) }
  it { is_expected.to validate_uniqueness_of(:rid).scoped_to(:team_id) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:team_id) }
  it { is_expected.to validate_uniqueness_of(:handle).scoped_to(:team_id) }

  describe '#find_with_team' do
    let(:team) { build(:team) }
    let!(:subteam) { create(:subteam, team:) }

    before do
      create(:subteam, rid: team.rid, team: build(:team))
    end

    it 'returns only subteams from given team' do
      expect(described_class.find_with_team(subteam.team.rid, subteam.rid)).to eq(subteam)
    end
  end

  describe '#matching scope' do
    let!(:subteam1) { create(:subteam, name: 'Dead Poets Society') }
    let!(:subteam2) { create(:subteam, handle: 'dead-poets-society') }

    before do
      create(:subteam, name: 'Alive Poets')
      create(:subteam, handle: 'alive-poets')
    end

    it 'returns only matching profiles' do
      expect(described_class.matching('dead')).to contain_exactly(subteam1, subteam2)
    end
  end
end
