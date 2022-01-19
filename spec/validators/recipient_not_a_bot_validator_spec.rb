# frozen_string_literal: true
require 'rails_helper'

RSpec.describe RecipientNotABotValidator do
  subject(:validate) { described_class.new.validate(tip) }

  let(:tip) { build(:tip, from_profile:, to_profile:) }
  let(:from_profile) { build(:profile) }
  let(:to_profile) { build(:profile) }
  let(:expected) do
    I18n.t \
      "activerecord.errors.models.tip.attributes.base.#{type}",
      user: from_profile.link,
      points: App.points_term
  end

  it 'is valid when to_profile is not a bot' do
    validate
    expect(tip.errors).to be_empty
  end

  context 'when to_profile is a bot' do
    let(:to_profile) { build(:profile, bot_user: true) }
    let(:type) { :cannot_tip_bots }

    it 'is invalid with generic message' do
      validate
      expect(tip.errors[:base]).to eq([expected])
    end

    context 'when to_profile is the app bot' do
      let(:type) { :cannot_accept_tips }

      before { to_profile.team.update(app_profile_rid: to_profile.rid) }

      it 'is invalid with self referential message' do
        validate
        expect(tip.errors[:base]).to eq([expected])
      end
    end
  end
end
