# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Slack::SlackApi do
  let(:api_key) { SecureRandom.hex }

  before do
    allow(Slack::Web::Client).to receive(:new)
  end

  shared_examples 'calls Slack client' do
    it 'calls Slack::Web::Client' do
      expect(Slack::Web::Client).to have_received(:new).with(token: api_key)
    end
  end

  context 'when team_rid is provided' do
    let(:team_rid) { FactoryHelper.slack_rid('T') }
    let(:cache_data) { { api_key: } }

    before do
      allow(Cache::TeamConfig).to receive(:call).with(:slack, team_rid).and_return(cache_data)
      described_class.client(team_rid:)
    end

    include_examples 'calls Slack client'
  end

  context 'when api_key is provided' do
    before { described_class.client(api_key:) }

    include_examples 'calls Slack client'
  end
end
