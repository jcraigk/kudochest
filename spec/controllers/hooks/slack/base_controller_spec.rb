# frozen_string_literal: true
require 'rails_helper'

describe Hooks::Slack::BaseController do
  include Rack::Test::Methods

  context 'when inherited and used in a child controller' do
    subject(:response) { post(hooks_slack_event_path, params) }

    let(:slack_request) { instance_spy(Slack::Events::Request) }
    let(:team) { build(:team) }
    let(:channel) { build(:channel) }
    let(:text) { 'nothing much' }
    let(:params) do
      {
        event: {
          team: team.rid,
          channel: channel.rid,
          text: text,
          type: 'message'
        }
      }
    end
    let(:result) { ChatResponse.new(mode: :foo, text: 'bar') }
    let(:team_config) { TeamConfig.new(active: true, topics: []) }

    before do
      allow(EventWorker).to receive(:perform_async)
      allow(Slack::Events::Request).to receive(:new).and_return(slack_request)
      allow(Cache::TeamConfig).to receive(:call).and_return(team_config)
    end

    describe 'verifies the Slack request is authentic' do
      before do
        allow(slack_request).to receive(:verify!)
      end

      it 'verifies the Slack request in before_action' do
        expect(response).to be_successful
        expect(slack_request).to have_received(:verify!)
      end
    end

    shared_examples 'ignores irrelevant messages' do
      let(:team_config) { TeamConfig.new(active: true) }

      before do
        allow(slack_request).to receive(:verify!).and_return(true)
        allow(Slack::PostService).to receive(:call)
      end

      it 'does not call Slack::PostService' do
        expect(response).to be_successful
        expect(Slack::PostService).not_to have_received(:call)
      end
    end

    describe 'when message is based on a bot message' do
      let(:params) { { message: { subtype: 'bot_message' } } }

      include_examples 'ignores irrelevant messages'
    end

    describe 'when event has a subtype' do
      let(:params) { { event: { subtype: 'anything' } } }

      include_examples 'ignores irrelevant messages'
    end

    describe 'when event has a bot_id' do
      let(:params) { { event: { bot_id: 'anything' } } }

      include_examples 'ignores irrelevant messages'
    end
  end
end
