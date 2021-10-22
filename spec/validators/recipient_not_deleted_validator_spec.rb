# frozen_string_literal: true
require 'rails_helper'

RSpec.describe RecipientNotDeletedValidator do
  subject(:validate) { described_class.new.validate(tip) }

  let(:tip) { build(:tip, from_profile: from_profile, to_profile: to_profile) }
  let(:from_profile) { build(:profile) }
  let(:to_profile) { build(:profile) }

  it 'is valid when to_profile is not deleted' do
    validate
    expect(tip.errors).to be_empty
  end

  context 'when to_profile is deleted' do
    let(:to_profile) { build(:profile, deleted: true) }
    let(:expected) do
      I18n.t(
        'activerecord.errors.models.tip.attributes.base.cannot_tip_deleted',
        user: from_profile.link,
        points: App.points_term
      )
    end

    it 'is invalid' do
      validate
      expect(tip.errors[:base]).to eq([expected])
    end
  end
end
