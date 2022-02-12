# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Tip do
  subject(:tip) { build(:tip) }

  it { is_expected.to be_a(ApplicationRecord) }

  it { is_expected.to belong_to(:from_profile).class_name('Profile').inverse_of(:tips_sent) }
  it { is_expected.to belong_to(:to_profile).class_name('Profile').inverse_of(:tips_received) }
  it { is_expected.to belong_to(:topic).optional(true) }

  it { is_expected.to validate_length_of(:note).is_at_most(App.max_note_length) }

  describe 'Topic presence validation' do
    subject(:tip) { build(:tip, from_profile: profile, topic: nil) }

    let(:team) { create(:team) }
    let(:profile) { create(:profile, team:) }

    context 'when team requires it' do
      before do
        team.update(require_topic: true)
        tip.validate
      end

      it 'is invalid without a topic' do
        expect(tip.errors[:topic_id]).to eq \
          ["must be specified - use the \"topics\" command or visit #{App.base_url}/topic-list"]
      end
    end

    context 'when team does not require it' do
      before do
        team.update(require_topic: false)
        tip.validate
      end

      it 'is valid without a topic' do
        expect(tip.errors[:topic_id]).to be_empty
      end
    end
  end

  describe 'scope #undoable', :freeze_time do
    let!(:tip1) { create(:tip, source: 'modal', from_profile: profile) }
    let!(:tip2) { create(:tip, source: 'inline', from_profile: profile) }
    let!(:tip3) { create(:tip, source: 'reply', from_profile: profile) }
    let!(:tip4) { create(:tip, source: 'streak', from_profile: profile) }
    let(:profile) { create(:profile) }

    before do
      create(:tip, source: 'modal', from_profile: profile, created_at: 1.year.ago) # old
    end

    it 'returns expected records' do
      expect(described_class.undoable).to match_array([tip1, tip2, tip3, tip4])
    end
  end

  describe 'scope #search_notes', :freeze_time do
    let!(:tip1) { create(:tip, note: 'Vishnu blah blah') }
    let!(:tip2) { create(:tip, note: 'something something vishnu') }

    before { create(:tip, note: 'Nothing to see here') }

    it 'returns expected records' do
      expect(described_class.search_notes('vish')).to match_array([tip1, tip2])
    end
  end

  describe 'custom validators' do
    let(:validators) { described_class.validators.map(&:class) }
    let(:expected_validators) do
      [
        QuantityValidator,
        RecipientNotABotValidator,
        RecipientNotDeletedValidator,
        RecipientNotSelfValidator
      ]
    end

    it 'validates with expected validators' do
      expect(validators).to include(*expected_validators)
    end
  end

  describe '#jab?' do
    context 'when quantity is negative' do
      before { tip.quantity = -1 }

      it 'is true' do
        expect(tip.jab?).to eq(true)
      end
    end

    context 'when quantity is positive' do
      before { tip.quantity = 1 }

      it 'is true' do
        expect(tip.jab?).to eq(false)
      end
    end
  end

  describe 'delete_slack_response after destroy' do
    subject(:tip) { create(:tip, response_channel_rid: channel.rid, response_ts: ts) }

    let(:ts) { Time.current.to_f.to_s }
    let(:channel) { build(:channel) }
    let(:expected_args) { { channel: channel.rid, ts: } }
    let(:slack_client) { instance_spy(Slack::Web::Client) }

    before do
      allow(Slack::Web::Client).to receive(:new).and_return(slack_client)
      allow(slack_client).to receive(:chat_delete)
      tip.destroy
    end

    it 'calls Slack::SlackApi.chat_delete' do
      expect(slack_client).to have_received(:chat_delete).with(expected_args)
    end
  end

  describe 'delete_discord_response after destroy' do
    subject(:tip) do
      create \
        :tip,
        from_profile: profile,
        response_channel_rid:
        channel.rid,
        response_ts: ts
    end

    let(:team) { create(:team, platform: :discord) }
    let(:profile) { create(:profile, team:) }
    let(:ts) { Time.current.to_f.to_s }
    let(:channel) { build(:channel) }
    let(:expected_args) { { channel: channel.rid, ts: } }

    before do
      allow(Discordrb::API::Channel).to receive(:delete_message)
      tip.destroy
    end

    it 'calls Slack::SlackApi.chat_delete' do
      expect(Discordrb::API::Channel)
        .to have_received(:delete_message).with(App.discord_token, channel.rid, ts)
    end
  end
end
