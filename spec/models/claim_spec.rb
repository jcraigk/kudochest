# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Claim do
  subject(:claim) { create(:claim) }

  it { is_expected.to be_a(ApplicationRecord) }

  it { is_expected.to belong_to(:reward) }
  it { is_expected.to belong_to(:profile) }

  it { is_expected.to validate_numericality_of(:price).is_greater_than(0) }

  describe '#fulfilled and #pending scopes' do
    let!(:fulfilled_claim) { create(:claim, fulfilled_at: Time.current) }
    let!(:pending_claim) { create(:claim) }

    it 'returns expected records' do
      expect(described_class.fulfilled).to eq([fulfilled_claim])
      expect(described_class.pending).to eq([pending_claim])
    end
  end

  describe 'scope #search', :freeze_time do
    let(:keyword) { 'abc' }
    let!(:claim1) { create(:claim, fulfillment_key: 'abcdef') }
    let!(:claim2) { create(:claim, fulfillment_key: '0asdabcasdf') }

    before { create(:claim, fulfillment_key: 'ddddd') }

    it 'returns expected records' do
      expect(described_class.search(keyword)).to match_array([claim1, claim2])
    end
  end

  it 'provides #fulfilled?' do
    expect(claim.fulfilled?).to eq(false)
    claim.fulfilled_at = Time.current
    expect(claim.fulfilled?).to eq(true)
  end

  it 'provides #pending?' do
    expect(claim.pending?).to eq(true)
    claim.fulfilled_at = Time.current
    expect(claim.pending?).to eq(false)
  end
end
