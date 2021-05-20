# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Discord::ProfileService do
  let(:expected_names) { %w[Existing Mark Vincent William Wolfgang] }
  let(:profile_data) do
    expected_names[1..].map do |username|
      {
        id: rand(100_000),
        username: username,
        bot: false
      }
    end + [
      {
        id: 'existing-rid',
        username: 'Existing',
        bot: false
      },
      {
        id: 'app-profile-rid',
        username: 'KarmaChest',
        bot: true
      },
      {
        id: rand(100_000),
        username: 'some-other-bot',
        bot: true
      }
    ]
  end

  before do
    ENV['DISCORD_APP_USERNAME'] = 'KarmaChest'
    allow(Discordrb::API::Server).to receive(:resolve_members)
      .with(App.discord_token, team.rid, 1_000).and_return(profile_data.to_json)
  end

  include_examples 'ProfileService'

  xcontext 'when avatar is missing' do
    it 'assigns a default one' do
    end
  end
end
