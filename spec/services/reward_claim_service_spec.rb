# frozen_string_literal: true
require 'rails_helper'

RSpec.describe RewardClaimService, :freeze_time do
  subject(:call) { described_class.call(profile: profile, reward: reward) }

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team: team, points_received: 100) }
  let(:reward) { create(:reward, team: team, price: 100, quantity: 1) }
  let(:base_attrs) do
    {
      reward_id: reward.id,
      profile_id: profile.id,
      price: reward.price
    }
  end

  shared_examples 'error' do
    it 'returns expected result' do
      expect(call.error).to eq(error)
    end
  end

  context 'when profile has insufficient points' do
    let(:error) { I18n.t('shop.insufficient_points', reward: reward.name, points: App.points_term) }

    before { profile.update(points_received: reward.price - 1) }

    include_examples 'error'
  end

  context 'when reward has insufficient quantity' do
    let(:error) { I18n.t('shop.insufficient_quantity') }

    context 'with auto_fulfill' do
      before { reward.update(auto_fulfill: true, fulfillment_keys: nil) }

      include_examples 'error'
    end

    context 'without auto_fulfill' do
      before { reward.update(quantity: 0) }

      include_examples 'error'
    end
  end

  context 'when claim is set to auto_fulfill' do
    let(:reward) { create(:reward, team: team, auto_fulfill: true, fulfillment_keys: "a\nb\nc") }

    it 'removes a key from the reward' do
      call
      expect(reward.reload.fulfillment_keys).to eq("b\nc")
    end

    it 'populates claim fulfillment_key' do
      claim = call.claim
      expect(claim.fulfillment_key).to eq('a')
      expect(claim.fulfilled_at).to eq(Time.current)
    end
  end

  it 'creates a claim' do
    claim = call.claim
    expect(claim.slice(base_attrs.keys).symbolize_keys).to eq(base_attrs)
  end
end
