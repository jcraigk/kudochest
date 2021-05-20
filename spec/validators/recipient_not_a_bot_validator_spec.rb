# frozen_string_literal: true
require 'rails_helper'

RSpec.describe RecipientNotABotValidator do
  subject(:validate) { described_class.new.validate(tip) }

  let(:tip) { build(:tip, to_profile: profile) }
  let(:profile) { build(:profile) }

  it 'is valid when to_profile is not a bot' do
    validate
    expect(tip.errors).to be_empty
  end

  context 'when to_profile is a bot' do
    let(:profile) { build(:profile, bot_user: true) }

    it 'is invalid with generic message' do
      validate
      expect(tip.errors[:base]).to eq(
        [I18n.t('activerecord.errors.models.tip.attributes.base.cannot_tip_bots')]
      )
    end

    context 'when to_profile is the app bot' do
      before { profile.team.update(app_profile_rid: profile.rid) }

      it 'is invalid with self referential message' do
        validate
        expect(tip.errors[:base]).to eq(
          [I18n.t('activerecord.errors.models.tip.attributes.base.cannot_accept_tips')]
        )
      end
    end
  end
end
