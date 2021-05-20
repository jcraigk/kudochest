# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Slack::ChannelMemberService do
  let(:slack_client) { instance_spy(Slack::Web::Client) }
  let(:channels_data) { { channel: { members: team.profiles.map(&:rid) } } }

  before do
    allow(Slack::Web::Client).to receive(:new).and_return(slack_client)
    allow(slack_client).to receive(:conversations_info).and_return(channels_data)
  end

  include_examples 'ChannelMemberService'
end
