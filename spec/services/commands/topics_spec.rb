# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Commands::Topics do
  subject(:command) { described_class.call(team_rid: team.rid, profile_rid: profile.rid) }

  let(:team) { create(:team, :with_app_profile) }
  let(:profile) { create(:profile, team:) }
  let!(:topic) { create(:topic, team:) }

  context 'when topics are disabled' do
    before { team.update(enable_topics: false) }

    it 'returns topics text' do
      result = command
      expect(result.mode).to eq(:private)
      expect(result.text).to eq('Topics are currently disabled')
    end
  end

  context 'when topics are enabled' do
    before { team.update(enable_topics: true) }

    it 'returns topics text' do
      result = command
      expect(result.mode).to eq(:private)
      expect(result.text).to include(topic.name)
    end
  end
end
