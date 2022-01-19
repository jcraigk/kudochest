# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TokenQuantityWithinTokenMaxValidator do
  subject(:validate) { described_class.new.validate(team) }

  let(:team) { build(:team, token_max: 10, token_quantity:) }

  context 'when token_quantity is less than token_max' do
    let(:token_quantity) { 5 }

    it 'is valid' do
      validate
      expect(team.errors).to be_empty
    end
  end

  context 'when token_quantity is equal to token_max' do
    let(:token_quantity) { 10 }

    it 'is valid when token_quantity is less than token_max' do
      validate
      expect(team.errors).to be_empty
    end
  end

  context 'when token_quantity exceeds token_max' do
    let(:token_quantity) { 15 }

    it 'is invalid' do
      validate
      expect(team.errors[:token_quantity]).to eq \
        [I18n.t('activerecord.errors.models.team.attributes.token_quantity.within_token_max')]
    end
  end
end
