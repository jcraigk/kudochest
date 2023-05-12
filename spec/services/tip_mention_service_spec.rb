require 'rails_helper'

RSpec.describe TipMentionService, :freeze_time do
  subject(:service) { described_class.call(**opts) }

  let(:team) do
    create(:team, throttle_tips: false, split_tip: false, tokens_disbursed_at: Time.current)
  end
  let(:channel) { create(:channel, team:) }
  let(:profile) { create(:profile, team:) }
  let(:to_profile) { create(:profile, team:) }
  let(:mentions) { [Mention.new(rid: "#{PROF_PREFIX}#{to_profile.rid}", quantity: 1)] }
  let(:note) { 'A note!' }
  let(:ts) { Time.current.to_f.to_s }
  let(:timestamp) { Time.current }
  let(:opts) do
    {
      channel_name: channel.name,
      channel_rid: channel.rid,
      event_ts: ts,
      message_ts: ts,
      mentions:,
      note:,
      profile:,
      source: 'inline',
      timestamp:
    }
  end

  shared_examples 'expected result' do
    it 'returns expected result' do
      expect(service).to eq(result)
    end
  end

  before do
    travel_to(Time.zone.local(2019, 11, 10, 21, 1, 1))
    allow(team.slack_client).to \
      receive(:chat_getPermalink).and_return(OpenStruct.new(permalink: 'link'))
  end

  context 'when `profile.announce_tip_sent `is false`' do
    let(:result) { ChatResponse.new(mode: :silent) }

    before do
      profile.update(announce_tip_sent: false, tokens_accrued: 10)
    end

    include_examples 'expected result'
  end

  context 'when sender requires more tokens' do
    let(:text) do
      <<~TEXT.squish
        :#{App.error_emoji}: Sorry #{profile.link}, your token balance of 0 is not sufficient. The next dispersal of #{team.token_quantity} tokens will occur in about 10 hours.
      TEXT
    end
    let(:result) { ChatResponse.new(mode: :error, text:) }

    before { team.update(throttle_tips: true) }

    include_examples 'expected result'
  end

  context 'when required note is missing' do
    let(:note) { '' }
    let(:text) { I18n.t('tips.note_required') }
    let(:result) { ChatResponse.new(mode: :error, text:) }

    before do
      profile.tokens_accrued = 10
      team.tip_notes = 'required'
    end

    include_examples 'expected result'
  end

  context 'when no mentions are provided' do
    let(:mentions) { [] }
    let(:result) do
      ChatResponse.new(mode: :error, text: I18n.t('errors.no_tips', user: profile.display_name))
    end

    include_examples 'expected result'
  end

  xcontext 'when `@everyone` is mentioned' do
    let(:mentions) { ['everyone'] }

    xit 'overrides other mentions' do
    end
  end

  xcontext 'when `@here` is mentioned' do
    let(:mentions) { ['here'] }

    xit 'overrides other mentions' do
    end
  end

  xcontext 'when team.split_tip is true' do
  end

  context 'when mixture of valid mentions are provided' do
    let(:mentions) do
      [
        Mention.new(rid: "#{PROF_PREFIX}#{to_profile.rid}", quantity: 1, topic_id: nil),
        Mention.new(rid: "#{CHAN_PREFIX}#{channel.rid}", quantity: 1, topic_id: nil),
        Mention.new(rid: "#{SUBTEAM_PREFIX[:slack]}#{subteam.rid}", quantity: 1, topic_id: nil)
      ]
    end
    let(:result) do
      ChatResponse.new \
        mode: :public,
        response: tip_response,
        tips: Tip.all,
        image: nil
    end
    let(:tip_response) { 'A mock tip response' }
    let(:mention_entities) do
      [
        EntityMention.new(entity: to_profile, profiles: [to_profile]),
        EntityMention.new(entity: subteam, profiles: [subteam_profile, other_profile]),
        EntityMention.new(entity: channel, profiles: [channel_profile])
      ]
    end
    let(:subteam) { create(:subteam, team:) }
    let(:subteam_profile) { create(:profile, team:) }
    let(:channel_profile) { create(:profile, team:) }
    let(:base_tip_attrs) do
      {
        event_ts: ts,
        message_ts: ts,
        from_channel_name: channel.name,
        from_channel_rid: channel.rid,
        from_profile: profile,
        note:,
        quantity: 1,
        topic_id: nil,
        source: 'inline',
        timestamp:
      }
    end
    let(:other_profile) { create(:profile, team:) }

    before do
      subteam.profiles << [subteam_profile, to_profile, other_profile]
      allow(TipFactory).to receive(:call)
      allow(TipResponseService).to receive(:call).and_return(tip_response)
      allow(Slack::ChannelMemberService)
        .to receive(:call).and_return([channel_profile, other_profile])
      service
    end

    it 'calls TipFactory for each unique profile, favoring direct, then subteam, then channel' do # rubocop:disable RSpec/ExampleLength
      mention_entities.each do |m|
        args = base_tip_attrs.merge \
          to_entity: m.entity.reload,
          to_profiles: m.profiles.map(&:reload),
          note: m.note
        expect(TipFactory).to have_received(:call).with(**args)
      end
    end
  end
end
