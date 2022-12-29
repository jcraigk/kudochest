# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Cache::TipModal do
  let(:channel) { build(:channel) }
  let(:str) { "#{channel.rid}:#{channel.name}" }
  let(:arg_key) { 'my-unique-key' }
  let(:cache_key) { "modal/#{arg_key}" }
  let(:expected_data) { ChannelData.new(channel.rid, channel.name) }

  before do
    allow(REDIS).to receive(:setex).and_call_original
    allow(REDIS).to receive(:del).and_call_original
    described_class.set(arg_key, channel.rid, channel.name)
  end

  it 'exposes #set' do
    expect(REDIS).to have_received(:setex).with(cache_key, App.modal_cache_ttl, str)
  end

  it 'exposes #get' do
    expect(described_class.get(arg_key)).to eq(expected_data)
  end
end
