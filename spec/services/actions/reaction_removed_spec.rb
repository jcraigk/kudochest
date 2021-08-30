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
  let(:slack_params) do
    {
      event: {
        item: {
          ts: ts
        },
        reaction: emoji
      }
    }
  end
  let(:discord_params) { { emoji: App.default_tip_emoji } }

  shared_examples 'success' do
    it 'destroys the tip' do
      expect { action }.to change(Tip, :count).by(-1)
    end
  end

  context 'when tip emoji' do
    let(:emoji) { team.tip_emoji }

    before do
      create(:tip, source: 'reaction', event_ts: ts, from_profile: sender)
    end

    context 'when slack' do
      let(:platform) { :slack }
      let(:params) { curated_params.merge(slack_params) }

      include_examples 'success'
    end

    context 'when discord' do
      let(:platform) { :discord }
      let(:params) { curated_params.merge(discord_params) }

      include_examples 'success'
    end
  end

  context 'when ditto emoji' do
    let(:emoji) { team.ditto_emoji }

    before do
      create(:tip, source: 'ditto', event_ts: ts, from_profile: sender)
    end

    context 'when slack' do
      let(:platform) { :slack }
      let(:params) { curated_params.merge(slack_params) }

      include_examples 'success'
    end

    context 'when discord' do
      let(:platform) { :discord }
      let(:params) { curated_params.merge(discord_params) }

      it 'destroys the tip' do
        expect { action }.to change(Tip, :count).by(-1)
      end
    end
  end
end
