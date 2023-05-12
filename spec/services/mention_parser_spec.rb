require 'rails_helper'

RSpec.describe MentionParser do
  subject(:service) { described_class.call(**opts) }

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team:) }
  let(:to_profile) { create(:profile, team:) }
  let(:to_profile2) { create(:profile, team:) }
  let(:channel) { create(:channel, team:) }
  let(:channel_name) { channel.name }
  let(:quantity) { 2 }
  let(:quantity2) { 2 }
  let(:note) { 'and here is a note' }
  let(:ts) { Time.current.to_f.to_s }
  let(:matches) do
    [
      {
        rid: to_profile.rid,
        inline: '++',
        suffix_quantity: 2,
        note:
      },
      {
        rid: to_profile2.rid,
        inline: '++',
        prefix_quantity: quantity2
      }
    ]
  end
  let(:opts) do
    {
      team_rid: team.rid,
      profile_rid: profile.rid,
      event_ts: ts,
      channel_rid: channel.rid,
      channel_name:,
      matches:
    }
  end
  let(:tip_mention_args) do
    {
      profile:,
      mentions:,
      source: 'inline',
      event_ts: ts,
      channel_rid: channel.rid,
      channel_name:
    }
  end
  let(:mentions) do
    [
      Mention.new(
        rid: to_profile.rid,
        quantity:,
        note:
      ),
      Mention.new(
        rid: to_profile2.rid,
        quantity: quantity2
      )
    ]
  end

  before do
    allow(TipMentionService).to receive(:call)
    service
  end

  it 'calls TipMentionService' do
    expect(TipMentionService).to have_received(:call).with(tip_mention_args)
  end

  xcontext 'when topic emoji is given' do
  end
end
