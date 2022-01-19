# frozen_string_literal: true
require 'rails_helper'

RSpec.shared_examples 'ProfileService' do
  subject(:service) { described_class.call(team:, first_run:) }

  let(:team) { create(:team, api_key: 'api-key') }
  let!(:existing_profile) { create(:profile, team:, rid: 'existing-rid') }
  let!(:extra_profile) { create(:profile, team:, display_name: 'Extra') }
  let(:display_names) { team.profiles.active.order(display_name: :asc).map(&:display_name) }
  let(:first_run) { false }

  before do
    allow(SubteamWorker).to receive(:perform_async)
    allow(TokenDispersalService).to receive(:call)
    service
  end

  it 'updates team.member_count' do
    expect(team.member_count).to eq(5)
  end

  it 'creates profiles' do
    expect(display_names).to eq(expected_names)
  end

  it 'updates existing profiles' do
    expect(existing_profile.reload.display_name).to eq('Existing')
  end

  it 'marks extra profiles as deleted' do
    expect(extra_profile.reload.deleted).to eq(true)
  end

  it 'updates team.app_profile_rid' do
    expect(team.app_profile_rid).to eq('app-profile-rid')
  end

  it 'assigns `bot_user`' do
    expect(team.profiles.where(bot_user: true).size).to eq(1)
  end

  context 'when first_run is true (initial team sync)' do
    let(:first_run) { true }

    it 'calls TokenDispersalService without notifications' do
      expect(TokenDispersalService).to have_received(:call).with(team:, notify: false)
    end

    it 'invokes SubteamWorker' do
      expect(SubteamWorker).to have_received(:perform_async).with(team.rid)
    end
  end
end
