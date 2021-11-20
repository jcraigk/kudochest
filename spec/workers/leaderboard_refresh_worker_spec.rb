# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LeaderboardRefreshWorker, :freeze_time do
  subject(:perform) { described_class.new.perform(team.id, givingboard) }

  let(:team) { create(:team) }
  let!(:result) { { updated_at: Time.current.to_i, profiles: ranked_profiles } }
  let(:profile1) do
    create \
      :profile,
      team: team,
      points: 10,
      last_tip_received_at: 1.day.ago,
      points_sent: 20,
      last_tip_sent_at: 1.day.ago,
      display_name: 'profile1'
  end
  let(:profile2) do
    create \
      :profile,
      team: team,
      points: 5,
      last_tip_received_at: 2.days.ago,
      points_sent: 20,
      last_tip_sent_at: 2.days.ago,
      display_name: 'profile2'
  end
  let(:profile3) do
    create \
      :profile,
      team: team,
      points: 13,
      last_tip_received_at: Time.current,
      points_sent: 10,
      last_tip_sent_at: 1.day.ago,
      display_name: 'profile3'
  end
  let(:profile4) do
    create \
      :profile,
      team: team,
      points: 13,
      last_tip_received_at: Time.current,
      display_name: 'profile4'
  end
  let(:profile5) do
    create \
      :profile,
      team: team,
      points: 20,
      last_tip_received_at: 3.days.ago,
      display_name: 'profile5'
  end
  let(:mock_cache) { instance_spy(Cache::Leaderboard) }
  let(:team_points) { 61 }

  before do
    team.update(points_sent: team_points)
    allow(Cache::Leaderboard).to receive(:new).and_return(mock_cache)
    allow(mock_cache).to receive(:set)
    perform
  end

  shared_examples 'success' do
    it 'calls Cache::Leaderboard.set with expected data' do
      expect(mock_cache).to have_received(:set).with(result)
    end
  end

  context 'when `givingboard` is false' do
    let(:givingboard) { false }
    let(:ranked_profiles) do
      [
        profile_data(profile5, 1, givingboard),
        profile_data(profile3, 2, givingboard),
        profile_data(profile4, 2, givingboard),
        profile_data(profile1, 3, givingboard),
        profile_data(profile2, 4, givingboard)
      ]
    end

    include_examples 'success'
  end

  context 'when `givingboard` is true' do
    let(:givingboard) { true }
    let(:ranked_profiles) do
      [
        profile_data(profile1, 1, givingboard),
        profile_data(profile2, 2, givingboard),
        profile_data(profile3, 3, givingboard)
      ]
    end

    include_examples 'success'
  end

  def profile_data(profile, rank, givingboard) # rubocop:disable Metrics/MethodLength
    verb = givingboard ? 'sent' : 'received'
    points_col = "points_#{verb}"
    LeaderboardProfile.new \
      id: profile.id,
      rank: rank,
      previous_rank: rank,
      slug: profile.slug,
      link: profile.profile_link,
      display_name: profile.display_name,
      real_name: profile.real_name,
      points: profile.send(points_col),
      percent_share: ((profile.send(points_col) / team_points.to_f) * 100).round(4),
      last_timestamp: profile.send("last_tip_#{verb}_at").to_i,
      avatar_url: profile.avatar_url
  end
end
