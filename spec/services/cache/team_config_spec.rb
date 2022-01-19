# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Cache::TeamConfig do
  subject(:cache) { described_class.new(team.rid) }

  let(:channel_rid) { build(:channel).rid }
  let(:team) { create(:team, log_channel_rid: channel_rid) }
  let(:cache_key) { "team_response_config/#{team.rid}" }
  let!(:topics) { create_list(:topic, 2, team:) }
  let(:team_attrs) { team.attributes.slice(*TeamConfig.members.map(&:to_s)) }
  let(:topic_attrs) do
    {
      topics: topics.map do |topic|
        TopicData.new(topic.attributes.slice(*TopicData.members.map(&:to_s)))
      end
    }
  end
  let(:expected) { TeamConfig.new(team_attrs.merge(topic_attrs)) }

  it 'returns expected data' do
    expect(cache.call).to eq(expected)
  end

  it 'deletes cache' do
    cache.delete
    expect(Rails.cache.fetch(cache_key)).to eq(nil)
  end
end
