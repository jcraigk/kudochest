# frozen_string_literal: true
require 'rails_helper'

RSpec.describe OneProfilePerTeamPerUserValidator do
  subject(:validate) { described_class.new.validate(profile) }

  let(:profile) { build(:profile, user_id: user.id, team_id: team.id) }
  let(:user) { create(:user) }
  let(:team) { create(:team) }

  it 'is valid when no conflicting profiles' do
    validate
    expect(profile.errors).to be_empty
  end

  context 'when user_id is nil' do
    before { profile.user_id = nil }

    it 'is valid' do
      validate
      expect(profile.errors).to be_empty
    end
  end

  context 'when conflicting profile exists' do
    before { create(:profile, user_id: user.id, team_id: team.id) }

    it 'is invalid' do
      validate
      expect(profile.errors[:base]).to eq \
        [I18n.t('activerecord.errors.models.profile.attributes.base.one_team_profile_per_user')]
    end
  end
end
