# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Commands::Claim do
  subject(:command) do
    described_class.call(team_rid: team.rid, profile_rid: profile.rid, text: text)
  end

  let(:team) { create(:team, enable_loot: enable_loot) }
  let(:profile) { create(:profile, team: team) }
  let(:text) { nil }

  shared_examples 'expected response' do
    it 'response as expected' do
      expect(command).to eq(response)
    end
  end

  context 'when team.enable_loot? is false' do
    let(:enable_loot) { false }
    let(:response) { OpenStruct.new(mode: :private, text: I18n.t('shop.disabled')) }

    include_examples 'expected response'
  end

  context 'when team.enable_loot? is true' do
    let(:enable_loot) { true }

    context 'with invalid reward name' do
      let(:text) { 'invalid name' }
      let(:response) do
        OpenStruct.new(
          mode: :error,
          text: ":#{App.error_emoji}: #{I18n.t('shop.unrecognized_reward')}"
        )
      end

      include_examples 'expected response'
    end

    context 'with valid reward name' do
      let!(:reward) { create(:reward, team: team, active: true) }
      let(:text) { reward.name }

      context 'when RewardClaimService returns error' do
        let(:error) { 'an error message' }
        let(:response) { OpenStruct.new(mode: :error, text: error) }

        before do
          allow(RewardClaimService).to(
            receive(:call).and_return(OpenStruct.new(error: error))
          )
        end

        include_examples 'expected response'
      end

      context 'when RewardClaimService returns success' do
        let(:error) { 'an error message' }
        let(:response) { OpenStruct.new(mode: :private, text: response_text) }
        let(:response_text) do
          <<~TEXT.chomp
            #{I18n.t('shop.claimed_for_karma', reward: reward.name, quantity: reward.price)}
            #{I18n.t('shop.fulfillment_pending')}
          TEXT
        end
        let(:claim) { create(:claim, reward: reward, profile: profile) }

        before do
          allow(RewardClaimService).to(
            receive(:call).and_return(OpenStruct.new(error: nil, claim: claim))
          )
        end

        include_examples 'expected response'
      end
    end
  end
end
