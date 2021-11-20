# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Commands::Shop do
  subject(:command) { described_class.call(team_rid: team.rid, profile_rid: profile.rid) }

  let(:team) { create(:team, enable_loot: enable_loot) }
  let(:profile) { create(:profile, team: team) }

  context 'when team.enable_loot? is false' do
    let(:enable_loot) { false }
    let(:response) { ChatResponse.new(mode: :private, text: I18n.t('shop.disabled')) }

    it 'returns shop empty' do
      expect(command).to eq(response)
    end
  end

  context 'when team.enable_loot? is true' do
    let(:enable_loot) { true }

    context 'when no rewards exist' do
      let(:response) { ChatResponse.new(mode: :private, text: I18n.t('shop.empty')) }

      it 'returns shop empty' do
        expect(command).to eq(response)
      end
    end

    context 'when rewards exist' do
      let!(:reward1) { create(:reward, team: team, active: true, quantity: 1) }
      let!(:reward2) { create(:reward, team: team, active: true, quantity: 1) }

      it 'returns shop empty' do
        expect(command.text).to include(reward1.name)
        expect(command.text).to include(reward2.name)
      end
    end
  end
end
