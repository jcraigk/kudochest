# frozen_string_literal: true
require 'rails_helper'

RSpec.describe HintService do
  subject(:call) { described_class.call(team: team) }

  let(:team) { create(:team, hint_frequency: 'daily', hint_channel_rid: 'foo') }

  before do
    allow(Slack::PostService).to receive(:call)
    call
  end

  it 'calls Slack::PostService' do
    expect(Slack::PostService).to have_received(:call)
  end
end
