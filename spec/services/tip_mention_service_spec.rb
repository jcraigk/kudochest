# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TipMentionService, :freeze_time do
  subject(:service) { described_class.call(opts) }

  let(:team) { create(:team, limit_karma: true, split_tip: false) }
  let(:channel) { create(:channel, team: team) }
  let(:profile) { create(:profile, team: team) }
  let(:to_profile) { create(:profile, team: team) }
  let(:mentions) { [OpenStruct.new(rid: "#{PROF_PREFIX}#{to_profile.rid}", quantity: 1)] }
  let(:note) { 'A note!' }
  let(:ts) { Time.current.to_f.to_s }
  let(:timestamp) { Time.current }
  let(:opts) do
    {
      channel_name: channel.name,
      channel_rid: channel.rid,
      event_ts: ts,
      mentions: mentions,
      note: note,
      profile: profile,
      source: 'plusplus',
      timestamp: timestamp
    }
  end

  shared_examples 'expected result' do
    it 'returns expected result' do
      expect(service).to eq(result)
    end
  end

  before { travel_to(Time.zone.local(2019, 11, 10, 21, 1, 1)) }

  context 'when sender requires more tokens' do
    let(:text) do
      <<~TEXT.squish
        :#{App.error_emoji}: Giving 1 karma would exceed your token balance of 0. The next dispersal of #{team.token_quantity} tokens will occur in about 10 hours.
      TEXT
    end
    let(:result) { OpenStruct.new(mode: :error, text: text) }

    include_examples 'expected result'
  end

  context 'when required note is missing' do
    let(:note) { '' }
    let(:text) { I18n.t('tips.note_required') }
    let(:result) { OpenStruct.new(mode: :error, text: text) }

    before do
      profile.tokens_accrued = 10
      team.tip_notes = 'required'
    end

    include_examples 'expected result'
  end

  context 'when no mentions are provided' do
    let(:mentions) { [] }
    let(:result) { nil }

    include_examples 'expected result'
  end

  xcontext 'when `@everyone` is mentioned' do
    xit 'overrides other mentions' do
    end
  end

  xcontext 'when team.split_tip is true' do
  end

  context 'when mixture of valid mentions are provided' do
    let(:mentions) do
      [
        OpenStruct.new(rid: "#{PROF_PREFIX}#{to_profile.rid}", quantity: 1, topic_id: nil),
        OpenStruct.new(rid: "#{CHAN_PREFIX}#{channel.rid}", quantity: 1, topic_id: nil),
        OpenStruct.new(rid: "#{SUBTEAM_PREFIX[:slack]}#{subteam.rid}", quantity: 1, topic_id: nil)
      ]
    end
    let(:result) do
      OpenStruct.new(
        mode: :public,
        response: tip_response,
        tips: Tip.all
      )
    end
    let(:tip_response) { 'A mock tip response' }
    let(:mention_entities) do
      [
        OpenStruct.new(entity: to_profile, profiles: [to_profile]),
        OpenStruct.new(entity: subteam, profiles: [subteam_profile, other_profile]),
        OpenStruct.new(entity: channel, profiles: [channel_profile])
      ]
    end
    let(:subteam) { create(:subteam, team: team) }
    let(:subteam_profile) { create(:profile, team: team) }
    let(:channel_profile) { create(:profile, team: team) }
    let(:base_tip_attrs) do
      {
        event_ts: ts,
        from_channel_name: channel.name,
        from_channel_rid: channel.rid,
        from_profile: profile,
        note: note,
        quantity: 1,
        topic_id: nil,
        source: 'plusplus',
        timestamp: timestamp
      }
    end
    let(:other_profile) { create(:profile, team: team) }

    before do
      team.limit_karma = false
      subteam.profiles << [subteam_profile, to_profile, other_profile]
      allow(TipFactory).to receive(:call).and_call_original
      allow(TipResponseService).to receive(:call).and_return(tip_response)
      allow(Slack::ChannelMemberService)
        .to receive(:call).and_return([channel_profile, other_profile])
    end

    it 'calls TipFactory for each unique profile, favoring direct, then subteam, then channel' do
      service
      mention_entities.each do |mh|
        args = base_tip_attrs.merge(to_entity: mh.entity, to_profiles: mh.profiles)
        expect(TipFactory).to have_received(:call).with(args)
      end
    end

    include_examples 'expected result'
  end
end
