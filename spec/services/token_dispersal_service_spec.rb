# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TokenDispersalService do
  subject(:service) { described_class.call(team:, notify:) }

  let(:team) { create(:team, platform:) }
  let(:platform) { :slack }
  let!(:profile1) { create(:profile, team:) }
  let!(:profile2) { create(:profile, team:) }
  let!(:profile3) { create(:profile, team:, infinite_tokens: true) }
  let(:quantity) { team.token_quantity }
  let(:max) { team.token_max }
  let(:notify) { true }

  before do
    travel_to(Time.zone.local(2019, 11, 8, 21, 1, 1))
    team.update(tokens_disbursed_at: Time.current)
    allow(Slack::PostService).to receive(:call)
  end

  context 'when `notify` option is true' do
    let(:response_base) do
      {
        team_config: team.config,
        team_rid: team.rid,
        mode: :direct,
        text: text
      }
    end

    let(:num_profiles) { [profile1, profile2].size }
    let(:profile1_response) { response_base.merge(profile_rid: profile1.rid) }
    let(:profile2_response) { response_base.merge(profile_rid: profile1.rid) }

    shared_examples 'text response' do
      it 'sends expected text' do
        service
        expect(Slack::PostService).to have_received(:call).with(profile1_response).once
        expect(Slack::PostService).to have_received(:call).with(profile2_response).once
      end
    end

    it 'increases token accrual for each active profile' do
      service
      expect(profile1.reload.tokens_accrued).to eq(quantity)
      expect(profile2.reload.tokens_accrued).to eq(quantity)
    end

    it 'does not increase when proflies.infinite_tokens?' do
      expect(profile3.reload.tokens_accrued).not_to eq(quantity)
    end

    it 'updates team.tokens_disbursed_at' do
      service
      expect(team.tokens_disbursed_at).to eq(Time.current)
    end

    it 'sends notification to each user' do
      service
      expect(Slack::PostService).to have_received(:call).exactly(num_profiles).times
    end

    context 'when no tokens are forfeited' do
      let(:text) do
        <<~TEXT.chomp
          You received #{quantity} tokens, bringing your total to #{quantity}. The next dispersal of #{quantity} tokens will occur in 2 days.
        TEXT
      end

      include_examples 'text response'
    end

    context 'when some or all tokens are forfeited' do
      let(:text) do
        <<~TEXT.chomp
          We tried to give you #{quantity} tokens, but you maxed out at #{max}. The next dispersal of #{quantity} tokens will occur in 2 days.
        TEXT
      end

      before do
        profile1.update(tokens_accrued: team.token_max - 3)
        profile2.update(tokens_accrued: team.token_max - 3)
      end

      include_examples 'text response'
    end
  end

  context 'when `notify` option is false' do
    let(:notify) { false }

    it 'does not send notifications' do
      service
      expect(Slack::PostService).not_to have_received(:call)
    end
  end

  context 'when `team.notify_tokens` option is false' do
    before { team.update(notify_tokens: false) }

    it 'does not send notifications' do
      service
      expect(Slack::PostService).not_to have_received(:call)
    end
  end

  context 'when `profile.allow_dm` is false' do
    before do
      profile1.update(allow_dm: false)
      profile2.update(allow_dm: false)
    end

    it 'does not send notifications' do
      service
      expect(Slack::PostService).not_to have_received(:call)
    end
  end
end
