# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Cache::Leaderboard do
  subject(:cache) { described_class.new(team.id, givingboard) }

  context 'when givinboard is false' do
    let(:key) { "leaderboard/#{team.id}/received" }
    let(:givingboard) { false }
    let(:team) { create(:team) }
    let(:val) { { a: 'a' } }

    describe 'set' do
      before do
        allow(RedisClient).to receive(:set)
        cache.set(val)
      end

      it 'calls RedisClient.set' do
        expect(RedisClient).to have_received(:set).with(key, val.to_json)
      end
    end

    describe 'get' do
      before do
        allow(RedisClient).to receive(:get)
        cache.get
      end

      it 'calls RedisClient.get' do
        expect(RedisClient).to have_received(:get).with(key)
      end
    end
  end
end
