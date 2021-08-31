# frozen_string_literal: true
require 'rails_helper'

RSpec.describe RecipientNotDeletedValidator do
  subject(:validate) { described_class.new.validate(tip) }

  let(:tip) { build(:tip, to_profile: profile) }
  let(:profile) { build(:profile) }

  it 'is valid when to_profile is not deleted' do
    validate
    expect(tip.errors).to be_empty
  end

  context 'when to_profile is deleted' do
    let(:profile) { build(:profile, deleted: true) }
    let(:expected) do
      I18n.t(
        'activerecord.errors.models.tip.attributes.base.cannot_tip_deleted',
        points: App.points_term
      )
    end

    it 'is invalid' do
      validate
      expect(tip.errors[:base]).to eq([expected])
    end
  end
end
