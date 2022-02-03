# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Discord::PostService do
  subject(:service) { described_class.call(**opts) }

  let(:team) { create(:team) }
  let(:opts) do
    {
      mode:,
      config: team.config,
      profile_rid: profile.rid,
      channel_rid: channel.rid,
      response:,
      text:,
      tips:
    }.compact
  end
  let(:channel) { create(:channel, team:, rid: 'pub-channel') }
  let(:profile) { create(:profile, team:) }
  let(:text) { '' }
  let(:chat_response) { 'Chat response' }
  let(:web_response) { 'Web response' }
  let(:response) do
    TipResponseService::TipResponse.new \
      chat_fragments: { main: chat_response },
      web: web_response
  end
  let(:post_response) do
    {
      channel_id: '1234',
      id: '5678'
    }
  end

  before do
    travel_to(Time.zone.local(2019, 11, 11, 21, 1, 1))
  end

  xcontext 'with `graphical` mode' do
  end

  context 'with `error`, `private`, and `direct` mode' do
    let(:mode) { :error }
    let(:text) { 'An error message' }
    let(:dm_channel_rid) { '12345' }
    let(:dm_channel_response) { { 'id' => dm_channel_rid } }
    let(:tips) { create_list(:tip, 2, from_profile: profile, from_channel_rid: channel.rid) }

    before do
      allow(Discordrb::API::User).to(
        receive(:create_pm).with(App.discord_token, profile.rid)
      ).and_return(dm_channel_response.to_json)
      allow(Discordrb::API::Channel).to(
        receive(:create_message).with(App.discord_token, dm_channel_rid, chat_response)
      ).and_return(post_response.to_json)
      service
    end

    it 'calls Discordrb::API::Channel#create_message with channel appended' do
      expect(Discordrb::API::Channel).to have_received(:create_message)
    end
  end

  context 'with `public` mode' do
    let(:mode) { :public }
    let(:tips) { create_list(:tip, 2, from_profile: profile, from_channel_rid: channel.rid) }

    before do
      allow(Discordrb::API::Channel).to(
        receive(:create_message).with(App.discord_token, channel.rid, chat_response)
      ).and_return(post_response.to_json)
      service
    end

    it 'calls Discordrb::API::Channel#create_message' do
      expect(Discordrb::API::Channel).to have_received(:create_message)
    end
  end
end
