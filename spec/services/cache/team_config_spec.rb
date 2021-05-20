# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Cache::TeamConfig do
  subject(:cache) { described_class.new(team.rid) }

  let(:channel_rid) { build(:channel).rid }
  let(:team) { create(:team, log_channel_rid: channel_rid) }
  let(:cache_key) { "team_response_config/#{team.rid}" }
  let!(:topics) { create_list(:topic, 2, team: team) }
  let(:team_attrs) { team.attributes.slice(*Team::CACHED_ATTRS) }
  let(:topic_attrs) do
    {
      topics: topics.map do |topic|
        OpenStruct.new(topic.attributes.slice('id', 'name', 'keyword', 'emoji'))
      end
    }
  end
  let(:response) { OpenStruct.new(team_attrs.merge(topic_attrs)) }

  it 'returns expected data' do
    expect(cache.call).to eq(response)
  end

  it 'deletes cache' do
    cache.delete
    expect(Rails.cache.fetch(cache_key)).to eq(nil)
  end
end
