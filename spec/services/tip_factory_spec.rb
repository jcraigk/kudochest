# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TipFactory do
  include ActionView::Helpers::TextHelper

  subject(:service) { described_class.call(**opts) }

  let(:team) { build(:team, split_tip:) }
  let(:topic) { create(:topic, team:) }
  let(:from_profile) { build(:profile, team:) }
  let(:from_channel) { build(:channel, team:) }
  let(:split_tip) { false }
  let(:note) do
    <<~TEXT
      A very long note that seems to go on forever. A very long note indeed. A very long note that seems to go on forever. A very long note indeed. A very long note that seems to go on forever. A very long note indeed.
    TEXT
  end
  let(:expected_note) { truncate(note, length: App.max_note_length, escape: false) }
  let(:ts) { Time.current.to_f.to_s }
  let(:timestamp) { Time.current }
  let(:opts) do
    {
      topic_id: topic.id,
      event_ts: ts,
      from_channel_name: from_channel.name,
      from_channel_rid: from_channel.rid,
      from_profile: from_profile,
      note: note,
      quantity: 1,
      source: 'seed',
      to_entity: to_entity,
      to_profiles: to_profiles,
      timestamp: timestamp
    }
  end
  let(:tip_attrs) do
    {
      chat_permalink:,
      created_at: timestamp,
      event_ts: ts,
      from_channel_name: from_channel.name,
      from_channel_rid: from_channel.rid,
      from_profile:,
      note: expected_note,
      quantity: 1,
      source: 'seed',
      topic_id: topic.id
    }.merge(extra_attrs)
  end
  let(:chat_permalink) { 'https://my-msg-permalink.org' }
  let(:extra_attrs) { {} }
  let(:slack_client) { instance_spy(Slack::Web::Client) }
  let(:permalink_args) do
    {
      channel: from_channel.rid,
      message_ts: ts
    }
  end

  shared_examples 'tip creation' do
    it 'creates a Tip for each to_profile' do
      service
      to_profiles.each do |to_profile|
        expect(Tip).to have_received(:create!).with(tip_attrs.merge(to_profile:))
      end
    end
  end

  before do
    allow(Tip).to receive(:create!)
    allow(team.slack_client).to \
      receive(:chat_getPermalink).and_return(OpenStruct.new(permalink: chat_permalink))
  end

  context 'when entity is a profile' do
    let(:to_entity) { build(:profile, team:) }
    let(:to_profiles) { [to_entity] }

    include_examples 'tip creation'

    context 'when team.split_tip is true' do
      let(:split_tip) { true }
      let(:quantity) { to_profiles.size }

      include_examples 'tip creation'
    end

    context 'when team.tip_notes are disabled' do
      let(:expected_note) { '' }

      before { team.tip_notes = 'disabled' }

      include_examples 'tip creation'
    end
  end

  context 'when entity is a channel' do
    let(:to_entity) { build(:channel, team:) }
    let(:to_profiles) { build_list(:profile, 2, team:) }
    let(:extra_attrs) do
      {
        to_channel_rid: to_entity.rid,
        to_channel_name: to_entity.name
      }
    end

    include_examples 'tip creation'
  end

  context 'when entity is a subteam' do
    let(:to_entity) { build(:subteam, team:) }
    let(:to_profiles) { build_list(:profile, 2, team:) }
    let(:extra_attrs) do
      {
        to_subteam_rid: to_entity.rid,
        to_subteam_handle: to_entity.handle
      }
    end

    include_examples 'tip creation'
  end

  context 'when entity is `everyone`' do
    let(:to_entity) { 'everyone' }
    let(:to_profiles) { build_list(:profile, 2, team:) }
    let(:extra_attrs) { { to_everyone: true } }
  end
end
