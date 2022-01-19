# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Slack::PostService do
  subject(:service) { described_class.call(**opts) }

  let(:opts) do
    {
      team_rid: team.rid,
      mode: mode,
      team_config: {
        log_channel_rid: team.log_channel_rid,
        response_mode:
      },
      channel_rid: channel.rid,
      is_bot_dm: false,
      message_ts: message_ts,
      profile_rid: profile.rid,
      response: response,
      text: text,
      thread_ts: thread_ts,
      tips: tips,
      trigger_id: trigger_id
    }.compact
  end
  let(:response_mode) { :convo }
  let(:team) { create(:team) }
  let(:profile) { create(:profile, team:) }
  let(:channel) { create(:channel) }
  let(:profile_rids) { [] }
  let(:thread_ts) { 'abc.def' }
  let(:trigger_id) { 'some-trigger' }
  let(:target_channel_rid) { channel.rid }
  let(:text) { '' }
  let(:chat_response) { 'A response' }
  let(:web_response) { 'A response' }
  let(:slack_client) { instance_spy(Slack::Web::Client) }
  let(:message_ts) { Time.current.to_f.to_s }
  let(:mock_chat_response) do
    {
      channel: channel.rid,
      ts: message_ts
    }
  end
  let(:tips) { {} }
  let(:response) do
    TipResponseService::TipResponse.new \
      chat_fragments: { main: chat_response },
      web: web_response
  end
  let(:web_ts) { '<span class="ts">Nov 11 9:01pm:</span>' }
  let(:text_block) do
    {
      type: :section,
      text: {
        type: :mrkdwn,
        text: chat_response
      }
    }
  end

  before do
    travel_to(Time.zone.local(2019, 11, 11, 21, 1, 1))
    allow(Slack::Web::Client).to receive(:new).and_return(slack_client)
  end

  context 'with `hint` mode' do
    let(:mode) { :hint }
    let(:arguments) do
      {
        blocks: [{ text: { text: chat_response, type: :mrkdwn }, type: :section }],
        channel: channel.rid,
        text: web_response,
        thread_ts:,
        unfurl_links: false,
        unfurl_media: false
      }
    end

    before do
      allow(slack_client).to receive(:chat_postMessage)
    end

    it 'calls chat_postMessage' do
      service
      expect(slack_client).to have_received(:chat_postMessage)
    end
  end

  context 'with `tip_modal` mode' do
    let(:mode) { :tip_modal }

    before { allow(Slack::Modals::Tip).to receive(:call) }

    it 'calls Slack::Modals::Tip' do
      service
      expect(Slack::Modals::Tip).to have_received(:call).with(team_rid: team.rid)
    end
  end

  context 'with `prefs_modal` mode' do
    let(:mode) { :prefs_modal }

    before { allow(Slack::Modals::Preferences).to receive(:call) }

    it 'calls Slack::Modals::Preferences' do
      service
      expect(Slack::Modals::Preferences).to \
        have_received(:call).with(team_rid: team.rid, profile_rid: profile.rid)
    end
  end

  context 'with `error` mode' do
    let(:mode) { :error }
    let(:text) { error_message }
    let(:error_message) { 'An error message' }
    let(:chat_response) { nil }
    let(:arguments) do
      {
        channel: channel.rid,
        user: profile.rid,
        text: error_message
      }
    end

    before do
      allow(slack_client).to receive(:chat_postEphemeral)
      service
    end

    it 'calls Slack::Web::Client#chat_postEphemeral' do
      expect(slack_client).to have_received(:chat_postEphemeral).with(arguments)
    end
  end

  context 'with `private` mode' do
    let(:mode) { :private }
    let(:chat_response) { '' }
    let(:arguments) do
      {
        channel: channel.rid,
        user: profile.rid,
        text: chat_response
      }
    end

    before do
      allow(slack_client).to receive(:chat_postEphemeral).and_return(mock_chat_response)
      service
    end

    it 'calls Slack::Web::Client#chat_postMessage' do
      expect(slack_client).to have_received(:chat_postEphemeral).with(arguments)
    end
  end

  xcontext 'with `graphical` mode' do
  end

  context 'when replacing a message (fast ack)' do
    let(:opts) { super().merge(replace_ts: message_ts) }

    context 'when response_mode is `silent`' do
      let(:mode) { :silent }

      before do
        allow(slack_client).to receive(:chat_delete)
        service
      end

      it 'deletes the original message' do
        expect(slack_client).to \
          have_received(:chat_delete).with(channel: channel.rid, ts: message_ts)
      end
    end

    context 'when response_mode is `public`' do
      let(:mode) { :public }

      before do
        allow(slack_client).to receive(:chat_update)
        service
      end

      it 'deletes the original message' do
        expect(slack_client).to have_received(:chat_update)
      end
    end
  end

  context 'with `public` mode' do
    let(:mode) { :public }

    before do
      allow(slack_client).to receive(:chat_postMessage).and_return(mock_chat_response)
    end

    xit 'if bot not in channel, falls back to ephemeral w/specific message' do
      # Slack::Web::Api::Errors::SlackError with message 'not_in_channel' or 'channel_not_found'
    end

    xcontext 'when response_mode is `adaptive`' do
      context 'when tip_source is `plusplus` or `modal`' do
        it 'responds as `convo`' do
        end
      end

      context 'when tip_source is `reaction` or `reply`' do
        it 'responds as `reply`' do
        end
      end

      context 'when is_bot_dm is `true`' do # could even nest inside `reply`
        it 'responds as dm' do
        end
      end
    end

    context 'when response_mode is `convo`' do
      let(:response_mode) { :convo }
      let(:arguments) do
        {
          text: chat_response,
          blocks: [text_block],
          channel: channel.rid,
          thread_ts: thread_ts,
          unfurl_links: false,
          unfurl_media: false
        }
      end

      it 'calls Slack::Web::Client#chat_postMessage' do
        service
        expect(slack_client).to have_received(:chat_postMessage).with(arguments)
      end
    end

    context 'when response_mode is `reply`' do
      let(:response_mode) { :reply }
      let(:replies_data) { { messages: [{ thread_ts: }] } }
      let(:arguments) do
        {
          text: chat_response,
          blocks: [text_block],
          channel: channel.rid,
          thread_ts:,
          unfurl_links: false,
          unfurl_media: false
        }
      end

      before do
        allow(slack_client).to \
          receive(:conversations_replies).with(
            channel: channel.rid,
            ts: message_ts
          ).and_return(replies_data)
      end

      it 'calls Slack::Web::Client#chat_postMessage' do
        service
        expect(slack_client).to have_received(:chat_postMessage).with(arguments)
      end
    end

    context 'when response_mode is `direct` and tips are passed in' do
      let(:tips) { create_list(:tip, 2, from_profile: profile) }
      let(:response_mode) { :direct }

      before do
        allow(ResponseChannel).to receive(:broadcast_to)
        service
      end

      it 'calls Slack::Web::Client#chat_postMessage' do # rubocop:disable RSpec/ExampleLength
        tips.each do |tip|
          expect(slack_client).to have_received(:chat_postMessage).with \
            text: chat_response,
            blocks: [text_block],
            channel: tip.to_profile.rid,
            as_user: true,
            unfurl_links: false,
            unfurl_media: false
        end
      end

      it 'updates tip response metadata' do
        tips.each do |tip|
          tip.reload
          expect(tip.response_channel_rid).to eq(channel.rid)
          expect(tip.response_ts).to eq(message_ts)
        end
      end

      it 'calls ResponseChannel.broadcast' do
        service
        expect(ResponseChannel).to have_received(:broadcast_to).with(team, response.web)
      end
    end

    # TODO: posts expected message in log channel in addition to contextual response
    # but only if tips present and source is different channel.
    # Take into account team.show_note and team.show_channel options as well
    xcontext 'when there is a specified log_channel_rid' do
      let(:log_channel_rid) { create(:channel).rid }
      let(:cache_response) do
        {
          response_mode: 'channel',
          log_channel_rid: log_channel_rid
        }
      end

      context 'when channel_rid != log_channel_rid' do
        let(:arguments) { { channel: channel.rid, text: chat_response } }

        it 'calls Slack::Web::Client#chat_postMessage a second time' do
        end
      end

      context 'when channel_rid == log_channel_rid' do
        let(:arguments) { { channel: log_channel_rid, text: chat_response } }

        it 'does not call Slack::Web::Client#chat_postMessage a second time' do
        end
      end
    end
  end
end
