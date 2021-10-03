# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LeaderboardService do
  subject(:service) { described_class.call(args) }

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team: team) }
  let(:cache_data) do
    OpenStruct.new(
      updated_at: Time.current.to_i,
      profiles: profiles
    )
  end
  let(:cache_giving_data) do
    OpenStruct.new(
      updated_at: Time.current.to_i,
      profiles: giving_profiles
    )
  end
  let(:mock_cache) { instance_spy(Cache::Leaderboard) }
  let(:mock_giving_cache) { instance_spy(Cache::Leaderboard) }
  let(:profiles) do
    [
      OpenStruct.new(id: 1, slug: 'profile1'),
      OpenStruct.new(id: 2, slug: 'profile2'),
      OpenStruct.new(id: 3, slug: 'profile3'),
      OpenStruct.new(id: 4, slug: 'profile4'),
      OpenStruct.new(id: 5, slug: 'profile5')
    ]
  end
  let(:giving_profiles) do
    [
      OpenStruct.new(id: 3, slug: 'profile3'),
      OpenStruct.new(id: 4, slug: 'profile4'),
      OpenStruct.new(id: 5, slug: 'profile5')
    ]
  end
  let(:result_ids) { service.profiles.pluck(:id) }

  before do
    profile.update(slug: 'profile3')
    allow(Cache::Leaderboard).to receive(:new).with(team.id, false).and_return(mock_cache)
    allow(Cache::Leaderboard).to receive(:new).with(team.id, true).and_return(mock_giving_cache)
    allow(mock_cache).to receive(:get).and_return(cache_data)
    allow(mock_giving_cache).to receive(:get).and_return(cache_giving_data)
  end

  shared_examples 'success' do
    it 'returns expectd leaderboard snippet' do
      expect(result_ids).to eq(expected_ids)
    end
  end

  context 'when count is given, truncates the list' do
    let(:args) { { team: team, count: 3 } }
    let(:expected_ids) { [1, 2, 3] }

    include_examples 'success'
  end

  context 'when profile and count are given, contextual snippet is returned' do
    let(:args) { { team: team, profile: profile, count: 3 } }
    let(:expected_ids) { [2, 3, 4] }

    include_examples 'success'
  end

  context 'when `givingboard` is true' do
    let(:args) { { team: team, givingboard: true } }
    let(:expected_ids) { [3, 4, 5] }

    include_examples 'success'
  end

  context 'when offset is given (paging)' do
    let(:args) { { team: team, count: 3, offset: 1 } }
    let(:expected_ids) { [2, 3, 4] }

    include_examples 'success'
  end
end
