# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TipFactory do
  include ActionView::Helpers::TextHelper

  subject(:service) { described_class.call(**opts) }

  let(:team) { create(:team, split_tip:) }
  let(:topic) { create(:topic, team:) }
  let(:from_profile) { create(:profile, team:) }
  let(:from_channel) { create(:channel, team:) }
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
      from_profile:,
      note:,
      quantity: 1,
      source: 'inline',
      to_entity:,
      to_profiles:,
      timestamp:
    }
  end
  let(:tip_attrs) do
    {
      created_at: timestamp,
      event_ts: ts,
      from_channel_name: from_channel.name,
      from_channel_rid: from_channel.rid,
      from_profile:,
      note: expected_note,
      quantity: 1,
      source: 'inline',
      topic_id: topic.id
    }.merge(extra_attrs)
  end
  let(:extra_attrs) { {} }

  shared_examples 'tip creation' do
    it 'creates a Tip and calls ChatPermalinkWorker for each to_profile' do
      service
      to_profiles.each do |to_profile|
        expect(Tip).to have_received(:create!).with(tip_attrs.merge(to_profile:))
      end
      expect(ChatPermalinkWorker).to have_received(:perform_async).exactly(to_profiles.size).times
    end
  end

  before do
    allow(Tip).to receive(:create!).and_call_original
    allow(ChatPermalinkWorker).to receive(:perform_async)
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

  context 'when entity is `here`' do
    let(:to_entity) { 'here' }
    let(:to_profiles) { build_list(:profile, 2, team:) }
    let(:extra_attrs) do
      {
        to_channel_rid: from_channel.rid,
        to_channel_name: from_channel.name,
        to_here: true
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
