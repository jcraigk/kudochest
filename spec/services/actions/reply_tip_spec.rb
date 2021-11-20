# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Actions::ReplyTip do
  subject(:action) { described_class.call(**params) }

  let(:team) { create(:team) }
  let(:sender) { create(:profile, team: team) }
  let(:recipient) { create(:profile, team: team) }
  let(:channel) { create(:channel, team: team) }
  let(:ts) { Time.current.to_f.to_s }
  let(:params) do
    {
      action: 'reply_tip',
      channel_name: channel.name,
      channel_rid: channel.rid,
      event_ts: ts,
      message_profile_rid: recipient.rid,
      message_ts: ts,
      profile_rid: sender.rid,
      team_config: TeamConfig.new,
      team_rid: team.rid
    }
  end
  let(:expected_args) do
    {
      profile: sender,
      mentions: [Mention.new(rid: "#{PROF_PREFIX}#{recipient.rid}", quantity: 1)],
      source: 'reply',
      event_ts: ts,
      channel_rid: channel.rid,
      channel_name: channel.name
    }
  end

  before do
    allow(TipMentionService).to receive(:call)
    action
  end

  it 'calls TipMentionService' do
    expect(TipMentionService).to have_received(:call).with(expected_args)
  end
end
