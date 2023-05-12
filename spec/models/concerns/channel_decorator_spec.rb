require 'rails_helper'

RSpec.describe ChannelDecorator do
  subject(:channel) { build(:channel) }

  describe '#link' do
    it 'returns expected text' do
      expect(channel.link).to eq("<#{CHAN_PREFIX}#{channel.rid}>")
    end
  end

  describe '#webref' do
    it 'returns expected text' do
      expect(channel.webref).to eq("<span class=\"chat-ref\">#{CHAN_PREFIX}#{channel.name}</span>")
    end
  end
end
