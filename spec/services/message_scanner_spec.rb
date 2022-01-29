# frozen_string_literal: true
require 'rails_helper'

RSpec.describe MessageScanner do
  subject(:call) { described_class.call(text, team.config) }

  let(:team) { create(:team) }
  let(:text) { '' }
  let(:matches) { [] }

  shared_examples 'success' do
    it 'returns expected regex' do
      expect(call).to eq(matches)
    end
  end

  context 'when emoji are disabled' do
    before { team.update(enable_emoji: false) }

    context 'when topics are enabled and present' do
      let(:text) { "@user ++ #{topic1.name} @user2++ #{topic2.name} #{note}" }
      let(:note) { 'way to go' }
      let(:topic1) { create(:topic, team:) }
      let(:topic2) { create(:topic, team:) }
      let(:topic3) { create(:topic, team:) }
      let(:matches) { [] }

      before do
        team.update(topics_enabled: true)
      end

      include_examples 'success'
    end
  end


  xcontext 'when emoji are enabled' do

    before { team.update(enable_emoji: true) }

    context 'without topics' do
    end

    context 'with topics' do
      let(:topic1) { create(:topic, team:) }
      let(:topic2) { create(:topic, team:) }
      let(:topic3) { create(:topic, team:) }
      let(:matches) { [] }
    end
  end
end
