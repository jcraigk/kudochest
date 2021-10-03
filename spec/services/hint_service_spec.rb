# frozen_string_literal: true
require 'rails_helper'

RSpec.describe HintService do
  subject(:call) { described_class.call(team: team) }

  let(:team) { create(:team, hint_frequency: 'daily', hint_channel_rid: 'foo') }
  let(:expected_args) do
    {
      team_rid: team.rid,
      team_config: team.config,
      mode: :hint,
      text: text
    }
  end
  let(:yaml) { { 'hints' => [hint] } }
  let(:hint) { 'a hint' }
  let(:text) { ":bulb: *Hint*: #{hint}" }

  before do
    allow(Slack::PostService).to receive(:call)
    allow(YAML).to receive(:safe_load).and_return(yaml)
    call
  end

  it 'calls Slack::PostService' do
    expect(Slack::PostService).to have_received(:call).with(expected_args)
  end
end
