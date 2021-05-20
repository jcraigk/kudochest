# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TokenRegisterable do
  subject(:profile) { create(:profile) }

  it { is_expected.to validate_uniqueness_of(:reg_token) }

  it 'generates reg_token on create' do
    expect(profile.reg_token).to match(/[a-z0-9]{10}/)
  end

  it 'resets the reg token' do
    old_token = profile.reg_token
    profile.reset_reg_token!
    expect(profile.reg_token).not_to eq(old_token)
  end
end
