# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Actions::AppHomeOpened, :freeze_time do
  subject(:action) { described_class.call(**params) }

  let(:team) { create(:team) }
  let!(:profile) { create(:profile, team:) }
  let(:params) { { team_rid: team.rid, profile_rid: profile.rid } }
  let(:expected_response) do
    ChatResponse.new \
      mode: :direct,
      text: I18n.t(
        'profiles.app_home_opened',
        app: App.app_name,
        url: App.help_url,
        points: App.points_term
      )
  end

  it 'returns a private response' do
    expect(action).to eq(expected_response)
  end

  it 'sets profile.welcomed_at' do
    action
    expect(profile.reload.welcomed_at).to eq(Time.current)
  end
end
