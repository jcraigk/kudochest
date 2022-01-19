# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Commands::Admin do
  include ActionView::Helpers::NumberHelper

  subject(:command) { described_class.call(team_rid: team.rid, profile_rid: profile.rid) }

  let(:user) { create(:user) }
  let(:team) { create(:team, owning_user: user, throttle_tips: true, enable_topics: true) }
  let(:profile) { create(:profile, team:) }
  let(:response) { ChatResponse.new(mode: :private, text:) }
  let(:text) do
    <<~TEXT.chomp
      *Throttle #{App.points_term.titleize}:* Yes
      *Exempt Users:* None
      *Token Dispersal Hour:* 7:00am
      *Token Dispersal Frequency:* Weekly
      *Token Dispersal Quantity:* #{team.token_quantity}
      *Token Max Balance:* #{team.token_max}
      *Minimum Increment:* #{points_format(team.tip_increment, label: true)}
      *Topics Enabled:* Yes
      *Topic Required:* No
      *Active Topics:* 0
      *Notes:* Optional
      *Emoji Enabled:* Yes
      *Emoji Value:* #{points_format(team.emoji_quantity, label: true)}
      *#{App.points_term.titleize} Emoji:* #{team.tip_emoj}
      *Ditto Emoji:* #{team.ditto_emoj}
      *Leveling Enabled:* Yes
      *Maximum Level:* #{team.max_level}
      *Required for Max Level:* #{points_format(team.max_level_points, label: true)}
      *Progression Curve:* Gentle
      *Streaks Enabled:* Yes
      *Streak Duration:* #{team.streak_duration} days
      *Streak Reward:* #{points_format(team.streak_reward, label: true)}
      *Time Zone:* (GMT+00:00) UTC
      *Work Days:* Monday, Tuesday, Wednesday, Thursday, Friday
      *Work Start Day:* Monday
      *Administrator:* #{admin_text}
    TEXT
  end

  shared_examples 'expected response' do
    it 'returns stats text' do
      expect(command).to eq(response)
    end
  end

  context 'when admin has not connected a team profile' do
    let(:admin_text) { user.email }

    include_examples 'expected response'
  end

  context 'when admin has connected a team profile' do
    let!(:profile) { create(:profile, team:, user:) }
    let(:admin_text) { "#{profile.link} (#{user.email})" }

    include_examples 'expected response'
  end
end
