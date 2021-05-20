# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Actions::ReactionRemoved do
  subject(:action) { described_class.call(params) }

  let(:team) { create(:team, platform: platform) }
  let(:sender) { create(:profile, team: team, tokens_accrued: 10) }
  let(:recipient) { create(:profile, team: team) }
  let(:ts) { Time.current.to_f }
  let(:curated_params) do
    {
      message_ts: ts,
      profile_rid: sender.rid,
      team_rid: team.rid
    }
  end

  shared_examples 'success' do
    it 'destroys the tip' do
      expect { action }.to change(Tip, :count).by(-1)
    end
  end

  before do
    create(:tip, source: 'reaction', event_ts: ts, from_profile: sender)
  end

  context 'when slack' do
    let(:platform) { :slack }
    let(:slack_params) do
      {
        event: {
          item: {
            ts: ts
          },
          reaction: team.karma_emoji
        }
      }
    end
    let(:params) { curated_params.merge(slack_params) }

    include_examples 'success'
  end

  context 'when discord' do
    let(:params) { curated_params.merge(emoji: App.discord_emoji) }
    let(:platform) { :discord }

    it 'destroys the tip' do
      expect { action }.to change(Tip, :count).by(-1)
    end
  end
end
