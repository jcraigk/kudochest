# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Commands::Settings do
  include ActionView::Helpers::NumberHelper

  subject(:command) { described_class.call(team_rid: team.rid, profile_rid: profile.rid) }

  let(:user) { create(:user) }
  let(:team) { create(:team, owning_user: user, limit_karma: true, enable_topics: true) }
  let(:profile) { create(:profile, team: team) }
  let(:response) { OpenStruct.new(mode: :private, text: text) }
  let(:text) do
    <<~TEXT.chomp
      *Limit Karma:* Yes
      *Exempt Users:* None
      *Token Dispersal Hour:* 7:00am
      *Token Dispersal Frequency:* Weekly
      *Token Dispersal Quantity:* #{team.token_quantity}
      *Token Max Balance:* #{team.token_max}
      *Minimum Karma Increment:* #{points_format(team.karma_increment)}
      *Topics Enabled:* Yes
      *Topic Required:* No
      *Active Topics:* 0
      *Karma Notes:* Optional
      *Emoji Enabled:* Yes
      *Emoji Icon:* #{team.karma_emoj}
      *Emoji Value:* #{points_format(team.emoji_quantity)}
      *Leveling Enabled:* Yes
      *Maximum Level:* #{team.max_level}
      *Maximum Level Karma:* #{number_with_delimiter(team.max_level_karma)}
      *Progression Curve:* Gentle
      *Streaks Enabled:* Yes
      *Streak Duration:* #{team.streak_duration} days
      *Streak Reward:* #{team.streak_reward} karma
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
    let!(:profile) { create(:profile, team: team, user: user) }
    let(:admin_text) { "#{profile.link} (#{user.email})" }

    include_examples 'expected response'
  end
end
