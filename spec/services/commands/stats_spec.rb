# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Commands::Stats do
  subject(:command) do
    described_class.call(team_rid: team.rid, profile_rid: profile_rid, text: request_text)
  end

  let(:team) { create(:team, throttle_tips: true) }
  let(:profile) { create(:profile, team: team) }
  let(:profile_rid) { profile.rid }
  let(:response) { OpenStruct.new(mode: :public, text: response_text) }
  let(:leaderboard_data) do
    OpenStruct.new(
      updated_at: Time.current,
      profiles: [
        OpenStruct.new(
          rank: rank
        )
      ]
    )
  end
  let(:rank) { 12 }

  shared_examples 'expected response' do
    it 'returns stats text' do
      expect(command).to eq(response)
    end
  end

  before do
    travel_to(Time.zone.local(2019, 11, 8, 21, 1, 1))
    allow(LeaderboardService).to receive(:call).and_return(leaderboard_data)
  end

  context 'when no profile given' do
    let(:request_text) { '' }
    let(:response_text) do
      <<~TEXT.chomp
        *Stats for #{profile.unobtrusive_link}*
        *Leaderboard Rank:* #{rank}
        *Level:* 1
        *#{App.points_term.titleize}:* 0
        *Given:* 0
        *Tokens:* 0 (receiving #{team.token_quantity} tokens in 2 days)
        *Giving Streak:* 0 days
        *Profile:* <#{profile.web_link}>
      TEXT
    end

    include_examples 'expected response'

    context 'with infinite_token profiles' do
      let(:response_text) do
        <<~TEXT.chomp
          *Stats for #{profile.unobtrusive_link}*
          *Leaderboard Rank:* #{rank}
          *Level:* 1
          *#{App.points_term.titleize}:* 0
          *Given:* 0
          *Tokens:* Unlimited
          *Giving Streak:* 0 days
          *Profile:* <#{profile.web_link}>
        TEXT
      end

      before { profile.update(infinite_tokens: true) }

      include_examples 'expected response'
    end
  end

  context 'when a profile is given' do
    let(:profile2) { create(:profile, team: team) }
    let(:request_text) { profile2.link }
    let(:response_text) do
      <<~TEXT.chomp
        *Stats for #{profile2.unobtrusive_link}*
        *Leaderboard Rank:* #{rank}
        *Level:* 1
        *#{App.points_term.titleize}:* 0
        *Given:* 0
        *Giving Streak:* 0 days
        *Profile:* <#{profile2.web_link}>
      TEXT
    end

    include_examples 'expected response'
  end

  context 'when team.enable_levels is false' do
    let(:profile2) { create(:profile, team: team) }
    let(:request_text) { profile2.link }
    let(:response_text) do
      <<~TEXT.chomp
        *Stats for #{profile2.unobtrusive_link}*
        *Leaderboard Rank:* #{rank}
        *#{App.points_term.titleize}:* 0
        *Given:* 0
        *Giving Streak:* 0 days
        *Profile:* <#{profile2.web_link}>
      TEXT
    end

    before { team.update(enable_levels: false) }

    include_examples 'expected response'
  end

  context 'when team.throttle_tips is false' do
    let(:profile2) { create(:profile, team: team) }
    let(:request_text) { profile2.link }
    let(:response_text) do
      <<~TEXT.chomp
        *Stats for #{profile2.unobtrusive_link}*
        *Leaderboard Rank:* #{rank}
        *Level:* 1
        *#{App.points_term.titleize}:* 0
        *Given:* 0
        *Giving Streak:* 0 days
        *Profile:* <#{profile2.web_link}>
      TEXT
    end

    before { team.update(throttle_tips: false) }

    include_examples 'expected response'
  end

  context 'when team.enable_streaks is false' do
    let(:profile2) { create(:profile, team: team) }
    let(:request_text) { profile2.link }
    let(:response_text) do
      <<~TEXT.chomp
        *Stats for #{profile2.unobtrusive_link}*
        *Leaderboard Rank:* #{rank}
        *Level:* 1
        *#{App.points_term.titleize}:* 0
        *Given:* 0
        *Profile:* <#{profile2.web_link}>
      TEXT
    end

    before { team.update(enable_streaks: false) }

    include_examples 'expected response'
  end
end
