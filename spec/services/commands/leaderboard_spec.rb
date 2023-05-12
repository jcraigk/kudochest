require 'rails_helper'

RSpec.describe Commands::Leaderboard, :freeze_time do
  subject(:command) do
    described_class.call(team_rid: team.rid, profile_rid: profile.rid, text:)
  end

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team:) }
  let(:profile1) { create(:profile, team:) }
  let(:profile2) { create(:profile, team:) }
  let(:profile3) { create(:profile, team:) }
  let(:profile4) { create(:profile, team:) }
  let(:profiles) { [profile1, profile2, profile3, profile4] }
  let(:text) { '' }

  shared_examples 'expected response' do
    let(:expected) { ChatResponse.new(mode: :public, text:) }

    it 'returns leaderboard text' do
      expect(command).to eq(expected)
    end
  end

  context 'when no tips have been given' do
    let(:text) { 'No activity yet. The leaderboard updates periodically.' }

    include_examples 'expected response'
  end

  context 'when some tips have been given' do
    let(:text) do
      <<~TEXT.chomp
        *Top 4 #{App.point_term.titleize} Earners*
        1. #{profile1.link} - #{points_format(500)} (less than a minute ago)
        2. #{profile2.link} - #{points_format(83)} (about 1 hour ago)
        2. #{profile3.link} - #{points_format(83)} (7 days ago)
        3. #{profile4.link} - #{points_format(3)} (2 months ago)
      TEXT
    end
    let(:mock_result) { LeaderboardPage.new(Time.current, profiles) }
    let(:profiles) do
      [
        profile_data(profile1, 1),
        profile_data(profile2, 2),
        profile_data(profile3, 2),
        profile_data(profile4, 3)
      ]
    end

    before do
      travel_to(Time.utc(2020, 1, 1, 1, 1))
      profile1.update(points: 500, last_tip_received_at: Time.current)
      profile2.update(points: 83, last_tip_received_at: 1.hour.ago)
      profile3.update(points: 83, last_tip_received_at: 1.week.ago)
      profile4.update(points: 3, last_tip_received_at: 2.months.ago)
      team.update(points_sent: profiles.sum(&:points))
      allow(LeaderboardPageService).to receive(:call).with(
        {
          team:,
          giving_board: false,
          jab_board: false
        }
      ).and_return(mock_result)
    end

    include_examples 'expected response'
  end

  xcontext 'with integer and `me` given after keyword' do
  end

  xcontext 'with `givers` given after keyword' do
  end

  xcontext 'with topic keyword or emoji given after command keyword' do
  end

  def profile_data(prof, rank)
    LeaderboardProfile.new \
      rank:,
      slug: prof.slug,
      link: prof.link,
      display_name: prof.display_name,
      real_name: prof.real_name,
      points: prof.points,
      last_timestamp: prof.last_tip_received_at.to_i
  end
end
