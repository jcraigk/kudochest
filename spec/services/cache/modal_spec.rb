# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Cache::Modal do
  let(:channel) { build(:channel) }
  let(:str) { "#{channel.rid}:#{channel.name}" }
  let(:arg_key) { 'my-unique-key' }
  let(:redis_key) { "modal/#{arg_key}" }
  let(:expected_data) do
    OpenStruct.new(
      channel_rid: channel.rid,
      channel_name: channel.name
    )
  end

  before do
    allow(RedisClient).to receive(:set).and_call_original
    allow(RedisClient).to receive(:del).and_call_original
    described_class.set(arg_key, channel.rid, channel.name)
  end

  it 'exposes #set' do
    expect(RedisClient).to have_received(:set).with(redis_key, str, ex: App.modal_cache_ttl)
  end

  it 'exposes #get' do
    expect(described_class.get(arg_key)).to eq(expected_data)
  end
end
