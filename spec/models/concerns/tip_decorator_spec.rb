require 'rails_helper'

RSpec.describe TipDecorator do
  subject(:tip) { build(:tip) }

  describe '#channel_webref' do
    it 'returns expected text' do
      expect(tip.channel_webref)
        .to eq("<span class=\"chat-ref\">#{CHAN_PREFIX}#{tip.from_channel_name}</span>")
    end
  end
end
