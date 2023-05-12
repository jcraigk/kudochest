require 'rails_helper'

RSpec.describe Reward do
  subject(:reward) { create(:reward) }

  it { is_expected.to be_a(ApplicationRecord) }

  it { is_expected.to belong_to(:team) }
  it { is_expected.to have_many(:claims).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:team_id) }
  it { is_expected.to validate_numericality_of(:price).is_greater_than(0) }

  describe 'custom validators' do
    let(:validators) { described_class.validators.map(&:class) }
    let(:expected_validators) do
      [
        QuantityCoversClaimCountValidator,
        AutoFulfillRequiresKeysValidator
      ]
    end

    it 'validates with expected validators' do
      expect(validators).to include(*expected_validators)
    end
  end

  describe '#active and #inactive scopes' do
    let!(:active_reward) { create(:reward, active: true) }
    let!(:inactive_reward) { create(:reward, active: false) }

    it 'returns expected records' do
      expect(described_class.active).to eq([active_reward])
      expect(described_class.inactive).to eq([inactive_reward])
    end
  end

  describe 'scope #search' do
    let(:keyword) { 'triforce' }
    let!(:reward1) { create(:reward, name: "#{keyword} blah blah") }
    let!(:reward2) { create(:reward, description: "blah#{keyword}blah") }

    before { create(:reward, name: 'Nutn') }

    it 'returns expected records' do
      expect(described_class.search(keyword)).to contain_exactly(reward1, reward2)
    end
  end

  xdescribe '#shop_list' do
  end
end
