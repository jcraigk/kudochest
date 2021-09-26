# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Actions::SubmitTipModal do
  subject(:action) { described_class.call(params) }

  let(:team) { build(:team) }
  let(:sender) { create(:profile, team: team) }
  let(:profile) { create(:profile, team: team) }
  let(:channel) { create(:channel, team: team) }
  let(:subteam) { create(:subteam, team: team) }
  let(:ts) { Time.current.to_f.to_s }
  let(:quantity) { 2 }
  let(:note) { 'A note' }
  let(:curated_params) do
    {
      channel_name: channel.name,
      channel_rid: channel.rid,
      message_ts: ts,
      profile_rid: sender.rid,
      team_rid: team.rid
    }
  end
  let(:modal_submission) do
    {
      trigger_id: "#{ts}.98098098ab098dsd",
      view: {
        state: {
          values: {
            JyY1m: {
              rids: {
                selected_options: selected_rid_options
              }
            },
            PNnF: {
              quantity: {
                selected_option: {
                  value: quantity
                }
              }
            },
            LdZbF: {
              note: {
                value: note
              }
            }
          }
        }
      }
    }
  end
  let(:params) { curated_params.merge(modal_submission) }

  before do
    allow(TipMentionService).to receive(:call)
  end

  context 'when no rids specified' do
    let(:selected_rid_options) { [] }

    it 'does not call TipMentionService' do
      action
      expect(TipMentionService).not_to have_received(:call)
    end
  end

  context 'when multiple rids specified' do
    let(:selected_rid_options) do
      [
        { value: profile.rid },
        { value: channel.rid },
        { value: subteam.rid },
        { value: 'everyone' }
      ]
    end
    let(:mentions) do
      [
        OpenStruct.new(rid: "#{PROF_PREFIX}#{profile.rid}", topic_id: nil, quantity: quantity),
        OpenStruct.new(rid: "#{CHAN_PREFIX}#{channel.rid}", topic_id: nil, quantity: quantity),
        OpenStruct.new(
          rid: "#{SUBTEAM_PREFIX[:slack]}#{subteam.rid}",
          topic_id: nil,
          quantity: quantity
        ),
        OpenStruct.new(rid: 'everyone', topic_id: nil, quantity: quantity)
      ]
    end
    let(:expected_args) do
      {
        profile: sender,
        mentions: mentions,
        note: note,
        source: 'modal',
        event_ts: ts,
        channel_rid: channel.rid,
        channel_name: channel.name
      }
    end

    it 'calls TipMentionService' do
      action
      expect(TipMentionService).to have_received(:call).with(expected_args)
    end
  end
end
