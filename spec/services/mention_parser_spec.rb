# frozen_string_literal: true
require 'rails_helper'

RSpec.describe MentionParser do
  subject(:service) { described_class.call(opts) }

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team: team) }
  let(:to_profile) { create(:profile, team: team) }
  let(:to_profile2) { create(:profile, team: team) }
  let(:channel) { create(:channel, team: team) }
  let(:channel_name) { channel.name }
  let(:quantity) { '2' }
  let(:quantity2) { '2' }
  let(:note) { 'and here is a note' }
  let(:ts) { Time.current.to_f.to_s }
  let(:matches) do
    [
      OpenStruct.new(
        profile_rid: to_profile.rid,
        prefix_digits: '',
        suffix_digits: 2
      ),
      OpenStruct.new(
        profile_rid: to_profile2.rid,
        prefix_digits: quantity2,
        suffix_digits: ''
      )
    ]
  end
  let(:opts) do
    {
      team_rid: team.rid,
      profile_rid: profile.rid,
      event_ts: ts,
      channel_rid: channel.rid,
      channel_name: channel_name,
      matches: matches,
      note: note
    }
  end
  let(:tip_mention_args) do
    {
      profile: profile,
      mentions: mentions,
      note: note,
      source: 'plusplus',
      event_ts: ts,
      channel_rid: channel.rid,
      channel_name: channel_name
    }
  end
  let(:mentions) do
    [
      OpenStruct.new(
        rid: to_profile.rid,
        quantity: quantity.to_i,
        topic_id: nil
      ),
      OpenStruct.new(
        rid: to_profile2.rid,
        quantity: quantity2.to_i,
        topic_id: nil
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
