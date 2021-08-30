# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Actions::ReactionAdded do
  subject(:action) { described_class.call(params) }

  let(:team) { build(:team) }
  let(:sender) { create(:profile, team: team) }
  let(:recipient) { create(:profile, team: team) }
  let(:channel) { create(:channel, team: team) }
  let(:ts) { Time.current.to_f.to_s }
  let(:curated_params) do
    {
      channel_rid: channel.rid,
      message_ts: ts,
      profile_rid: sender.rid,
      team_rid: team.rid,
      event_ts: ts
    }
  end
  let(:slack_params) do
    {
      event: {
        reaction: reaction,
        item: {
          ts: ts,
          channel: channel.rid
        },
        item_user: recipient.rid
      }
    }
  end
  let(:params) { curated_params.merge(slack_params) }

  before { allow(TipMentionService).to receive(:call) }

  shared_examples 'exits' do
    it 'does not call TipMentionService' do
      action
      expect(TipMentionService).not_to have_received(:call)
    end
  end

  context 'when reaction is tip emoji' do
    let(:reaction) { team.tip_emoji }
    let(:expected_args) do
      {
        profile: sender,
        mentions: [
          OpenStruct.new(
            rid: "#{PROF_PREFIX}#{recipient.rid}",
            quantity: 1,
            topic_id: nil
          )
        ],
        source: 'reaction',
        event_ts: ts,
        channel_rid: channel.rid,
        channel_name: channel.name
      }
    end

    it 'calls TipMentionService' do
      action
      expect(TipMentionService).to have_received(:call).with(expected_args)
    end

    context 'when team.enable_emoji is false' do
      before { team.enable_emoji = false }

      include_examples 'exits'
    end
  end

  context 'when reaction is ditto emoji' do
    let(:reaction) { team.ditto_emoji }
    let(:expected_args) do
      {
        profile: sender,
        mentions: [
          OpenStruct.new(
            rid: "#{PROF_PREFIX}#{recipient.rid}",
            quantity: 1,
            topic_id: nil
          )
        ],
        source: 'reaction',
        event_ts: ts,
        channel_rid: channel.rid,
        channel_name: channel.name
      }
    end

    xit 'calls TipMentionService' do
      action
      expect(TipMentionService).to have_received(:call).with(expected_args)
    end
  end

  xcontext 'when reaction is topic emoji' do
  end

  context 'when reaction is not correct emoji' do
    let(:reaction) { 'invalid_emoji' }

    include_examples 'exits'
  end

  context 'when discord' do
    let(:reaction) { App.default_tip_emoji }
    let(:params) { curated_params.merge(emoji: App.default_tip_emoji) }

    before { team.platform = :discord }

    it 'calls TipMentionService' do
      action
      expect(TipMentionService).to have_received(:call)
    end
  end
end
