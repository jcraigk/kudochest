# frozen_string_literal: true
require 'rails_helper'

RSpec.describe MessageScanner do
  subject(:call) { described_class.call(text, team.config) }

  let(:team) { create(:team) }
  let(:matches) { [] }
  let(:text) { '' }
  let(:note) { 'way to go' }
  let(:note2) { 'thank you' }
  let(:rid1) { '@UNNW3U043' }
  let(:rid2) { '@UNNW3U044' }

  shared_examples 'success' do
    it 'returns expected matches' do
      expect(call).to eq(matches)
    end
  end

  context 'with topic keywords' do
    let!(:topic1) { create(:topic, team:) }
    let!(:topic2) { create(:topic, team:) }
    let(:text) { "<#{rid1}>++2 #{topic1.keyword} <#{rid2}> 3-- #{topic2.keyword} #{note}" }
    let(:matches) do
      [
        {
          rid: rid1,
          prefix_digits: nil,
          inline_text: '++',
          inline_emoji: nil,
          suffix_digits: 2,
          topic_keyword: topic1.keyword,
          note: nil
        },
        {
          rid: rid2,
          prefix_digits: 3,
          inline_text: '--',
          inline_emoji: nil,
          suffix_digits: nil,
          topic_keyword: topic2.keyword,
          note:
        }
      ]
    end

    include_examples 'success'
  end

  context 'with inline emoji' do
    let(:text) do
      "<#{rid1}> #{team.point_emoj} #{team.point_emoj} #{note} " \
        "<#{rid2}>#{team.jab_emoj} #{note2}"
    end
    let(:matches) do
      [
        {
          rid: rid1,
          prefix_digits: nil,
          inline_text: nil,
          inline_emoji: "#{team.point_emoj}#{team.point_emoj}",
          suffix_digits: nil,
          topic_keyword: nil,
          note:
        },
        {
          rid: rid2,
          prefix_digits: nil,
          inline_text: nil,
          inline_emoji: team.jab_emoj,
          suffix_digits: nil,
          topic_keyword: nil,
          note: note2
        }
      ]
    end

    include_examples 'success'
  end
end
