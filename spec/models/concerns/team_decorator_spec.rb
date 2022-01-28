# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TeamDecorator do
  subject(:team) { build(:team) }

  describe '#levels_table' do
    subject(:team) do
      build(:team, max_level: 10, max_level_points: 450, level_curve: :steep)
    end

    let(:expected_text) do
      <<~TEXT.strip
        Level  #{App.points_term.titleize}  Delta
        -----  -----  -----
        1      0      0
        2      5      5
        3      20     15
        4      45     25
        5      82     37
        6      131    49
        7      193    62
        8      266    73
        9      352    86
        10     450    98
      TEXT
    end

    it 'returns expected text' do
      expect(team.levels_table).to eq(expected_text)
    end
  end

  describe 'infinite_profiles_sentence' do
    context 'when no infinite profiles' do
      let(:sentence) { 'None' }

      it 'returns expected sentence' do
        expect(team.infinite_profiles_sentence).to eq(sentence)
      end
    end

    context 'when infinite profiles exist' do
      let!(:profile2) do
        create(:profile, team:, display_name: 'A1', infinite_tokens: true)
      end
      let!(:profile3) do
        create(:profile, team:, display_name: 'B1', infinite_tokens: true)
      end
      let(:sentence) { "#{profile2.link} and #{profile3.link}" }

      before do
        create(:profile, team:) # limited profile
      end

      it 'returns expected sentence' do
        expect(team.infinite_profiles_sentence).to eq(sentence)
      end
    end
  end

  describe 'workspace_noun' do
    context 'when slack' do
      before { team.platform = :slack }

      it 'is `workspace`' do
        expect(team.workspace_noun).to eq('workspace')
      end
    end

    context 'when discord' do
      before { team.platform = :discord }

      it 'is `guild`' do
        expect(team.workspace_noun).to eq('guild')
      end
    end
  end

  describe 'point_emoj' do
    it 'is the default tip emoji' do
      expect(team.point_emoj).to eq(":#{App.default_point_emoji}:")
    end
  end

  describe 'ditto_emoj' do
    it 'is the default ditto emoji' do
      expect(team.ditto_emoj).to eq(":#{App.default_ditto_emoji}:")
    end
  end
end
