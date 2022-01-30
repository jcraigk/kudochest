# frozen_string_literal: true
require 'rails_helper'

RSpec.shared_context 'with Slack request verification and active team' do
  let(:slack_request) { instance_spy(Slack::Events::Request) }

  before do
    allow(Slack::Events::Request).to receive(:new).and_return(slack_request)
    allow(slack_request).to receive(:verify!).and_return(true)
    allow(Cache::TeamConfig).to receive(:call).and_return(
      {
        active: true,
        app_profile_rid: team.app_profile_rid,
        platform: 'slack'
      }
    )
  end
end
