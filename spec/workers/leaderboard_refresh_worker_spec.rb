# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LeaderboardRefreshWorker, :freeze_time do
  subject(:perform) { described_class.new.perform(team.id, giving_board, jab_board) }

  let(:team) { create(:team, points_sent: team_points, deduct_jabs:) }
  let(:deduct_jabs) { true }
  let(:result) { { updated_at: Time.current.to_i, profiles: ranked_profiles } }
  let(:profile1) do
    create \
      :profile,
      team:,
      balance: 10,
      points_received: 12,
      points_sent: 20,
      jabs_received: 2,
      jabs_sent: 17,
      last_tip_sent_at: 1.day.ago,
      last_tip_received_at: 1.day.ago,
      display_name: 'profile1'
  end
  let(:profile2) do
    create \
      :profile,
      team:,
      balance: 5,
      points_received: 5,
      points_sent: 20,
      jabs_received: 0,
      jabs_sent: 2,
      last_tip_sent_at: 2.days.ago,
      last_tip_received_at: 2.days.ago,
      display_name: 'profile2'
  end
  let(:profile3) do
    create \
      :profile,
      team:,
      balance: 11,
      points_received: 12,
      points_sent: 10,
      jabs_received: 1,
      jabs_sent: 0,
      last_tip_sent_at: 1.day.ago,
      last_tip_received_at: 1.day.ago,
      display_name: 'profile3'
  end
  let(:profile4) do
    create \
      :profile,
      team:,
      balance: 13,
      points_received: 13,
      points_sent: 0,
      jabs_received: 0,
      jabs_sent: 0,
      last_tip_sent_at: Time.current,
      last_tip_received_at: Time.current,
      display_name: 'profile4'
  end
  let(:profile5) do
    create \
      :profile,
      team:,
      balance: 13,
      points_received: 16,
      points_sent: 25,
      jabs_received: 3,
      jabs_sent: 4,
      last_tip_sent_at: 3.days.ago,
      last_tip_received_at: 3.days.ago,
      display_name: 'profile5'
  end
  let(:mock_cache) { instance_spy(Cache::Leaderboard) }
  let(:team_points) { 61 }
  let(:all_profiles) { [profile1, profile2, profile3, profile4, profile5] }

  before do
    allow(Cache::Leaderboard).to receive(:new).and_return(mock_cache)
    allow(mock_cache).to receive(:set)
    all_profiles
    perform
  end

  shared_examples 'success' do
    it 'calls Cache::Leaderboard.set with expected data' do
      expect(mock_cache).to have_received(:set).with(result)
    end
  end

  context 'when `giving_board` and `jab_board` are false' do
    let(:giving_board) { false }
    let(:jab_board) { false }
    let(:ranked_profiles) do
      [
        profile_data(profile4, 1, giving_board, jab_board, deduct_jabs),
        profile_data(profile5, 2, giving_board, jab_board, deduct_jabs),
        profile_data(profile1, 3, giving_board, jab_board, deduct_jabs),
        profile_data(profile3, 3, giving_board, jab_board, deduct_jabs),
        profile_data(profile2, 4, giving_board, jab_board, deduct_jabs)
      ]
    end

    include_examples 'success'

    context 'when `deduct_jabs` is false' do
      let(:deduct_jabs) { false }
      let(:ranked_profiles) do
        [
          profile_data(profile5, 1, giving_board, jab_board, deduct_jabs),
          profile_data(profile4, 2, giving_board, jab_board, deduct_jabs),
          profile_data(profile1, 3, giving_board, jab_board, deduct_jabs),
          profile_data(profile3, 3, giving_board, jab_board, deduct_jabs),
          profile_data(profile2, 4, giving_board, jab_board, deduct_jabs)
        ]
      end

      include_examples 'success'
    end
  end

  context 'when `giving_board` is true' do
    let(:giving_board) { true }
    let(:jab_board) { false }
    let(:ranked_profiles) do
      [
        profile_data(profile5, 1, giving_board, jab_board, deduct_jabs),
        profile_data(profile1, 2, giving_board, jab_board, deduct_jabs),
        profile_data(profile2, 3, giving_board, jab_board, deduct_jabs),
        profile_data(profile3, 4, giving_board, jab_board, deduct_jabs)
      ]
    end

    include_examples 'success'
  end

  context 'when `jab_board` is true' do
    let(:giving_board) { false }
    let(:jab_board) { true }
    let(:ranked_profiles) do
      [
        profile_data(profile5, 1, giving_board, jab_board, deduct_jabs),
        profile_data(profile1, 2, giving_board, jab_board, deduct_jabs),
        profile_data(profile3, 2, giving_board, jab_board, deduct_jabs)
      ]
    end

    include_examples 'success'
  end

  context 'when `giving_board` and `jab_board` are both true' do
    let(:giving_board) { true }
    let(:jab_board) { true }
    let(:ranked_profiles) do
      [
        profile_data(profile1, 1, giving_board, jab_board, deduct_jabs),
        profile_data(profile5, 2, giving_board, jab_board, deduct_jabs),
        profile_data(profile2, 3, giving_board, jab_board, deduct_jabs)
      ]
    end

    include_examples 'success'
  end

  def profile_data(profile, rank, giving_board, jab_board, deduct_jabs) # rubocop:disable Metrics/MethodLength
    points_col ||=
      if giving_board
        jab_board ? :jabs_sent : :points_sent
      elsif jab_board
        :jabs_received
      else
        deduct_jabs ? :balance : :points_received
      end
    verb = giving_board ? :sent : :received
    LeaderboardProfile.new \
      id: profile.id,
      rank:,
      previous_rank: rank,
      slug: profile.slug,
      link: profile.dashboard_link,
      display_name: profile.display_name,
      real_name: profile.real_name,
      points: profile.send(points_col),
      last_timestamp: profile.send("last_tip_#{verb}_at").to_i,
      avatar_url: profile.avatar_url
  end
end
