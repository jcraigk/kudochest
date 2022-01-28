# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Actions::Message do
  subject(:action) { described_class.call(**params) }

  let(:team) { build(:team, platform:) }
  let(:sender) { create(:profile, team:) }
  let(:profile) { create(:profile, team:) }
  let(:channel) { create(:channel, team:) }
  let(:subteam) { create(:subteam, team:) }
  let(:ts) { Time.current.to_f.to_s }
  let(:note) { 'for being awesome' }
  let(:platform) { :slack }
  let(:params) do
    {
      platform: platform,
      team_rid: team.rid,
      config: TeamConfig.new(
        app_profile_rid: team.app_profile_rid,
        app_subteam_rid: team.app_subteam_rid
      ),
      channel_name: channel.name,
      channel_rid: channel.rid,
      event_ts: ts,
      origin: origin,
      profile_rid: sender.rid,
      text: text
    }
  end
  let(:expected_args) do
    {
      profile: sender,
      mentions: mentions,
      note: note,
      source: 'inline',
      event_ts: ts,
      channel_rid: channel.rid,
      channel_name: channel.name
    }
  end
  let(:origin) { 'channel' }
  let(:bot_mention) { "<#{PROFILE_PREFIX[platform]}#{team.app_profile_rid}>" }
  let(:user_mention) { "#{PROFILE_PREFIX[platform]}#{profile.rid}" }

  before do
    allow(TipMentionService).to receive(:call)
  end

  shared_examples 'success' do
    it 'calls TipMentionService' do
      action
      expect(TipMentionService).to have_received(:call).with(expected_args)
    end
  end

  shared_examples 'silence' do
    it 'returns nil' do
      expect(action).to eq(nil)
    end
  end

  shared_examples 'platform parity' do
    context 'when text does not contain punctuation or bot mention' do
      let(:text) { 'hello world' }

      include_examples 'silence'
    end

    context 'when text is bot mention only' do
      let(:text) { bot_mention }

      include_examples 'silence'
    end

    context 'when text starts with bot mention and contains other text' do
      let(:text) { "#{bot_mention} stats opt1 opt2" }
      let(:command_args) do
        {
          team_rid: team.rid,
          profile_rid: sender.rid,
          text: 'opt1 opt2'
        }
      end

      before { allow(Commands::Stats).to receive(:call) }

      it 'calls Command with opts text' do
        action
        expect(Commands::Stats).to have_received(:call).with(command_args)
      end
    end

    context 'when text includes `++` but no entity' do
      let(:text) { "hello ++ #{note}" }
      let(:mentions) { [] }
      let(:note) { nil }

      include_examples 'silence'
    end

    context 'when text includes `++` with user mention' do
      let(:text) { "hello <#{user_mention}> ++ #{note}" }
      let(:mentions) do
        [Mention.new(rid: user_mention, topic_id: nil, quantity: 1)]
      end

      include_examples 'success'
    end

    context 'when text includes `++2` with user mention' do
      let(:text) { "hello <#{user_mention}> ++2 #{note}" }
      let(:mentions) do
        [Mention.new(rid: user_mention, topic_id: nil, quantity: 2)]
      end

      include_examples 'success'
    end

    xcontext 'when text include `@everyone++`' do
    end

    context 'when text includes `+=` with valid user' do
      let(:text) { "hello <#{user_mention}> += #{note}" }
      let(:mentions) do
        [Mention.new(rid: user_mention, quantity: 1, topic_id: nil)]
      end

      include_examples 'success'
    end

    context 'when text includes single valid inline emoji with valid user' do
      let(:text) { "hello <#{user_mention}> :#{team.tip_emoji}: #{note}" }
      let(:mentions) do
        [Mention.new(rid: user_mention, quantity: 1, topic_id: nil)]
      end

      include_examples 'success'
    end

    context 'when text includes single valid inline emoji with int suffix' do
      let(:text) { "hello <#{user_mention}> :#{team.tip_emoji}: 2 #{note}" }
      let(:mentions) do
        [Mention.new(rid: user_mention, quantity: 2, topic_id: nil)]
      end

      include_examples 'success'
    end

    context 'when text includes single valid inline emoji with int prefix' do
      let(:text) { "hello <#{user_mention}> 2 :#{team.tip_emoji}: #{note}" }
      let(:mentions) do
        [Mention.new(rid: user_mention, quantity: 2, topic_id: nil)]
      end

      include_examples 'success'
    end

    context 'when text includes multiple valid inline emoji with int suffix' do
      let(:text) do
        <<~TEXT.chomp
          hello <#{user_mention}> :#{team.tip_emoji}: :#{team.tip_emoji}: :#{team.tip_emoji}: 2 #{note}
        TEXT
      end
      let(:mentions) do
        [Mention.new(rid: user_mention, quantity: 3, topic_id: nil)]
      end

      include_examples 'success'
    end

    context 'when text includes multiple mixed inline emoji with valid user' do
      let(:text) do
        "hello <#{user_mention}> :#{team.tip_emoji}: :invalid_emoji::#{team.tip_emoji}: #{note}"
      end
      let(:mentions) do
        [Mention.new(rid: user_mention, quantity: 2, topic_id: nil)]
      end

      include_examples 'success'
    end

    context 'when text includes `++` with mixture of entities, spacing, and quantities' do
      let(:text) do
        <<~TEXT.chomp
          hello <#{user_mention}>++ #{subteam_mention} 2++5 <#{CHAN_PREFIX}#{channel.rid}> ++3 #{note}
        TEXT
      end
      let(:mentions) do
        [
          Mention.new(
            rid: "#{PROFILE_PREFIX[platform]}#{profile.rid}",
            quantity: 1,
            topic_id: nil
          ),
          Mention.new(
            rid: "#{SUBTEAM_PREFIX[platform]}#{subteam.rid}",
            quantity: 2,
            topic_id: nil
          ),
          Mention.new(
            rid: "#{CHAN_PREFIX}#{channel.rid}",
            quantity: 3,
            topic_id: nil
          )
        ]
      end

      include_examples 'success'
    end
  end

  context 'when Slack' do
    let(:platform) { :slack }
    let(:subteam_mention) do
      "<#{SUBTEAM_PREFIX[platform]}#{subteam.rid}|#{PROF_PREFIX}#{subteam.handle}>"
    end

    include_examples 'platform parity'

    context 'when command is issued with no keyword' do
      let(:origin) { 'command' }
      let(:text) { '' }

      it 'opens a modal' do
        expect(action).to eq(ChatResponse.new(mode: :tip_modal))
      end
    end
  end

  context 'when Discord' do
    let(:platform) { :discord }
    let(:subteam_mention) { "<#{SUBTEAM_PREFIX[platform]}#{subteam.rid}>" }

    include_examples 'platform parity'
  end
end
