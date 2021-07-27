# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TeamResetService do
  subject(:call) { described_class.call(team: team) }

  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:profile) { create(:profile, team: team, user: user) }
  let(:received_tips) { create_list(:tip, 3, to_profile: profile) }
  let(:sent_tips) { create_list(:tip, 3, from_profile: profile) }
  let(:response_attrs) do
    {
      team_rid: team.rid,
      profile_rid: profile.rid,
      mode: :direct,
      text: I18n.t('teams.stats_reset'),
      team_config: team.config
    }
  end

  before do
    travel_to(Time.zone.local(2019, 11, 5))
    received_tips
    sent_tips
    allow(TokenDispersalService).to receive(:call)
    allow(Slack::PostService).to receive(:call)
  end

  it 'deletes existing tips' do
    expect { call }.to change(Tip, :count).by(-6)
  end

  it 'resets profile stats' do
    call
    expect(profile.reload.points_received).to eq(0)
    expect(profile.reload.points_sent).to eq(0)
  end

  it 'resets team stats' do
    call
    expect(team.points_sent).to eq(0)
  end

  it 'disburses fresh tokens' do
    call
    expect(TokenDispersalService).to have_received(:call).with(team: team, notify: false)
  end

  context 'when profile.allow_unprompted_dm is true' do
    before { profile.update(allow_unprompted_dm: true) }

    it 'notifies users' do
      call
      expect(Slack::PostService).to have_received(:call).with(response_attrs)
    end
  end

  context 'when profile.allow_unprompted_dm is false' do
    before { profile.update(allow_unprompted_dm: false) }

    it 'does not notify users' do
      call
      expect(Slack::PostService).not_to have_received(:call)
    end
  end
end
