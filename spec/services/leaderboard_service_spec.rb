# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LeaderboardService, :freeze_time do
  subject(:service) { described_class.call(args) }

  let(:team) { create(:team) }
  let(:result) do
    OpenStruct.new(
      updated_at: Time.current,
      profiles: ranked_profiles
    )
  end
  let(:profile1) do
    create(:profile, team: team, points: 10, last_tip_received_at: 1.day.ago,
                     display_name: 'profile1')
  end
  let(:profile2) do
    create(:profile, team: team, points: 5, last_tip_received_at: 2.days.ago,
                     display_name: 'profile2')
  end
  let(:profile3) do
    create(:profile, team: team, points: 13, last_tip_received_at: Time.current,
                     display_name: 'profile3')
  end
  let(:profile4) do
    create(:profile, team: team, points: 13, last_tip_received_at: Time.current,
                     display_name: 'profile4')
  end
  let(:profile5) do
    create(:profile, team: team, points: 20, last_tip_received_at: 3.days.ago,
                     display_name: 'profile5')
  end

  shared_examples 'success' do
    it 'returns snippet of ranked profiles' do
      expect(service).to eq(result)
    end
  end

  before { allow(team).to receive(:points_sent).and_return(team_points) }

  xcontext 'when empty team is given' do
    let(:args) { { team: team } }
    let(:ranked_profiles) { [] }
    let(:team_points) { 0 }

    include_examples 'success'
  end

  xcontext 'when team with profiles is given' do
    let(:args) { { team: team } }
    let(:team_points) { 61 }
    let!(:ranked_profiles) do # rubocop:disable RSpec/LetSetup
      [
        profile_data(profile5, 1),
        profile_data(profile3, 2),
        profile_data(profile4, 2),
        profile_data(profile1, 3),
        profile_data(profile2, 4)
      ]
    end

    include_examples 'success'
  end

  xcontext 'when team and count are given, truncates the list' do
    let(:args) { { team: team, count: 3 } }
    let(:team_points) { 61 }
    let!(:ranked_profiles) do # rubocop:disable RSpec/LetSetup
      [
        profile_data(profile5, 1),
        profile_data(profile3, 2),
        profile_data(profile4, 2)
      ]
    end

    before do # Profiles that are outside count scope
      create(:profile, team: team, points: 5) # profile2
      create(:profile, team: team, points: 10) # profile1
    end

    include_examples 'success'
  end

  xcontext 'when profile and count are given, contextual snippet is returned' do
    let(:args) { { team: team, profile: profile3, count: 3 } }
    let(:team_points) { 61 }
    let!(:ranked_profiles) do # rubocop:disable RSpec/LetSetup
      [
        profile_data(profile5, 2), # 20 points
        profile_data(profile3, 3), # 13 points
        profile_data(profile4, 3) # 13 points
      ]
    end

    before do # Profiles that are outside count scope
      create(:profile, team: team, points: 30, display_name: 'extra-rank-1') # Rank: 1
      create(:profile, team: team, points: 5, display_name: 'extra-rank-5') # Rank: 5
    end

    include_examples 'success'
  end

  xcontext 'when previous_rank was positive on a profile' do
    let(:args) { { team: team, count: 3 } }
    let(:result) do
      OpenStruct.new(
        updated_at: Time.current,
        profiles: [
          profile_data(profile4, 1, 1),
          profile_data(profile3, 2, 2),
          profile_data(profile1, 3, 2)
        ]
      )
    end
    let(:tip_last_week) { create(:tip, to_profile: profile4, quantity: 5) }
    let(:created_at) { Time.current - 10.days }
    let(:team_points) { 41 }

    before do
      tip_last_week.update(created_at: created_at)
      result
    end

    include_examples 'success'
  end

  xcontext 'when `givingboard` is true' do
  end

  xcontext 'when offset is given (paging)' do
  end

  xcontext 'when profiles have same points but one is earned more recently' do
    it 'ranks the one earned more recently higher' do
    end
  end

  xcontext 'when topic_id is given' do
    it 'ranks based on tips constrained to specified topic_id' do
    end
  end

  def profile_data(profile, rank, previous_rank = 0) # rubocop:disable Metrics/MethodLength
    profile.reload
    OpenStruct.new(
      id: profile.id,
      rank: rank,
      previous_rank: previous_rank,
      slug: profile.slug,
      link: profile.link,
      display_name: profile.display_name,
      real_name: profile.real_name,
      points: profile.points,
      percent_share: (profile.points / team_points.to_f) * 100,
      last_timestamp: profile.last_tip_received_at.to_s,
      avatar_url: profile.avatar_url
    )
  end
end
