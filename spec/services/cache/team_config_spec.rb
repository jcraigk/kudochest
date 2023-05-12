require 'rails_helper'

RSpec.describe Cache::TeamConfig do
  subject(:cache) { described_class.new(team.platform, team.rid) }

  let(:channel_rid) { build(:channel).rid }
  let(:team) { create(:team, log_channel_rid: channel_rid) }
  let(:cache_key) { "config/#{team.platform}/#{team.rid}" }
  let!(:topics) { create_list(:topic, 2, team:) }
  let(:team_attrs) { team.attributes.slice(*Team::CONFIG_ATTRS) }
  let(:topic_attrs) do
    {
      topics: topics.sort_by(&:name).map do |topic|
        topic.attributes.slice('id', 'name', 'keyword', 'emoji').symbolize_keys
      end
    }
  end
  let(:expected) { team_attrs.merge(topic_attrs).deep_symbolize_keys }

  it 'returns expected data' do
    expect(cache.call).to eq(expected)
  end

  it 'deletes cache' do
    cache.delete
    expect(Rails.cache.fetch(cache_key)).to be_nil
  end
end
