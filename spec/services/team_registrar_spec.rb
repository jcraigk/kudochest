# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TeamRegistrar, :freeze_time do
  subject(:service) { described_class.call(opts) }

  let(:opts) do
    {
      platform: :slack,
      rid: team.rid,
      name: team.name,
      api_key: team.api_key,
      owner_user_id: team.owner_user_id,
      avatar_url: 'url230'
    }
  end
  let(:slack_client) { instance_spy(Slack::Web::Client) }
  let(:team_attrs) do
    {
      platform: :slack,
      response_mode: :adaptive,
      rid: team.rid,
      name: team.name,
      owner_user_id: team.owner_user_id,
      api_key: team.api_key,
      avatar_url: 'url230',
      installed: true
    }
  end

  before do
    allow(App).to receive(:max_teams).and_return(100)
    allow(Slack::Web::Client).to receive(:new).and_return(slack_client)
    allow(team).to receive(:sync_remote)
  end

  context 'when no team with RID exists' do
    let(:team) { build(:team) }
    let(:mock_mailer) { instance_spy(ActionMailer::MessageDelivery) }

    before do
      allow(Team).to receive(:create!).and_return(team)
      service
    end

    it 'creates a Team and calls #sync_remote on it' do
      expect(Team).to have_received(:create!).with(team_attrs)
      expect(team).to have_received(:sync_remote).with(first_run: true)
    end
  end

  context 'when team with RID exists' do
    let!(:team) { create(:team, owning_user: create(:user)) }

    before do
      allow(Team).to receive(:find_by).with(rid: team.rid).and_return(team)
      allow(team).to receive(:update!)
      service
    end

    it 'updates existing team and calls #sync_remote on it' do
      expect(team).to have_received(:update!)
      expect(team).to have_received(:sync_remote).with(first_run: true)
    end
  end
end
