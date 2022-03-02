# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TokenLimitService do
  subject(:service) { described_class.call(profile:, quantity:) }

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team:) }
  let(:quantity) { 2 }

  context 'when team.throttle_tips is true' do
    before do
      team.update(throttle_tips: true)
    end

    context 'when profile.infinite_tokens is true' do
      before { profile.infinite_tokens = true }

      it 'returns false' do
        expect(service).to be(false)
      end
    end

    context 'when profile.accrued_tokens is sufficient' do
      before { profile.tokens_accrued = 2 }

      it 'returns false' do
        expect(service).to be(false)
      end
    end

    context 'when profile.accrued_tokens is not sufficient' do
      let(:text) do
        <<~TEXT.chomp
          :#{App.error_emoji}: Sorry #{profile.link}, your token balance of 1 is not sufficient.
        TEXT
      end

      before do
        profile.tokens_accrued = 1
      end

      it 'returns text' do
        expect(service).to include(text)
      end
    end
  end

  context 'when team.throttle_tips is false' do
    before do
      team.update(throttle_tips: false)
    end

    it 'returns false' do
      expect(service).to be(false)
    end
  end
end
