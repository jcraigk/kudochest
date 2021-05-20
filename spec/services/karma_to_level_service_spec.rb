# frozen_string_literal: true
require 'rails_helper'

RSpec.describe KarmaToLevelService do
  subject(:call) { described_class.call(team: team, karma: karma) }

  let(:team) do
    create(
      :team,
      max_level: max_level,
      max_level_karma: max_level_karma,
      level_curve: curve
    )
  end
  let(:max_level) { 20 }
  let(:max_level_karma) { 500 }
  let(:karma) { 259 }

  context 'with gentle curve' do
    let(:curve) { 'gentle' }

    it 'returns expected level' do
      expect(call).to eq(13)
    end

    context 'when karma is zero' do
      let(:karma) { 0 }

      it 'returns 1' do
        expect(call).to eq(1)
      end
    end
  end

  context 'with steep curve' do
    let(:curve) { 'steep' }

    it 'returns expected level' do
      expect(call).to eq(14)
    end
  end

  context 'with linear curve' do
    let(:curve) { 'linear' }

    it 'returns expected level' do
      expect(call).to eq(10)
    end
  end

  context 'with max level attained' do
    let(:curve) { 'linear' }
    let(:karma) { 10_000 }

    it 'returns expected level' do
      expect(call).to eq(max_level)
    end
  end
end
