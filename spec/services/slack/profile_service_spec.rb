# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Slack::ProfileService, vcr: { cassette_name: 'slack/profile_service' } do
  let(:expected_names) { %w[Existing Mark Vincent William Wolfgang] }

  before do
    allow(App).to receive(:slack_app_id).and_return('slack-app-id')
  end

  include_examples 'ProfileService'
end
