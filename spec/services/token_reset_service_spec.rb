# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TokenResetService do
  subject(:service) { described_class.call(team: team) }

  let(:team) { create(:team, :with_profiles, limit_karma: true) }

  it 'calls resets tokens_accrued on profiles' do
    service
    team.profiles.each do |profile|
      expect(profile.reload.token_balance).to eq(App.default_token_quantity)
    end
  end
end
