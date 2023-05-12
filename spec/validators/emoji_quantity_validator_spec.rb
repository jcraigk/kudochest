require 'rails_helper'

RSpec.describe EmojiQuantityValidator do
  subject(:validate) { described_class.new.validate(team) }

  let(:team) { build(:team, tip_increment:, emoji_quantity:) }
  let(:tip_increment) { 1.0 }
  let(:emoji_quantity) { 1.0 }

  shared_examples 'invalid' do
    it 'is invalid' do
      validate
      expect(team.errors[:emoji_quantity]).to eq \
        ["must be a multiple of the #{App.points_term.titleize} Increment (#{team.tip_increment})"]
    end
  end

  shared_examples 'valid' do
    it 'is valid' do
      validate
      expect(team.errors).to be_empty
    end
  end

  context 'when emoji_quantity is 0.25 and tip_increment is 0.25' do
    let(:tip_increment) { 0.25 }
    let(:emoji_quantity) { 0.25 }

    include_examples 'valid'
  end

  context 'when emoji_quantity is 0.25 and tip_increment is 0.01' do
    let(:tip_increment) { 0.01 }
    let(:emoji_quantity) { 0.25 }

    include_examples 'valid'
  end

  context 'when emoji_quantity is 0.01 and tip_increment is 0.25' do
    let(:tip_increment) { 0.25 }
    let(:emoji_quantity) { 0.01 }

    include_examples 'invalid'
  end
end
