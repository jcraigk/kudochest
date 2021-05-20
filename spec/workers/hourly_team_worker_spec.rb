# frozen_string_literal: true
require 'rails_helper'

RSpec.describe HourlyTeamWorker do
  subject(:perform) { described_class.new.perform }

  # TODO: Adjust timezones on each team, ensure daylight savings works
  # Also ensure travel_to works (seems it was using actual current time)
  let(:current_hour) { Time.current.hour }
  let!(:team1) { create(:team, token_hour: current_hour) }
  let!(:team2) { create(:team, token_hour: current_hour) }
  let(:frequency) { 'weekly' }
  let(:mock_relation) { instance_spy(ActiveRecord::Relation) }
  let(:current_time) { Time.zone.local(2019, 11, 8, 21, 1, 1) }

  before do
    travel_to(current_time)
    allow(TokenDispersalWorker).to receive(:perform_async)
    allow(mock_relation).to receive(:find_each).and_yield(team1).and_yield(team2)
  end

  context 'with mixture of active and inactive teams' do
    let!(:team4) do
      create(
        :team,
        token_frequency: 'weekly',
        token_hour: current_hour
      )
    end
    let!(:team5) do
      create(
        :team,
        token_frequency: 'monthly',
        token_hour: current_hour
      )
    end
    let!(:team6) do
      create(
        :team,
        token_frequency: 'monthly',
        token_hour: current_hour,
        active: false
      )
    end

    before do
      allow(Team).to receive(:where).with(limit_karma: true).and_return(mock_relation)
      allow(mock_relation).to \
        receive(:find_each).and_yield(team1).and_yield(team2).and_yield(team4).and_yield(team5)
      travel_to((Time.current + 1.month).change(hour: current_hour))
      perform
    end

    it 'calls TokenDispersalWorker on monthly team once' do
      expect(TokenDispersalWorker).to have_received(:perform_async).with(team5.id)
    end

    it 'does not call TokenDispersalWorker on inactive monthly team' do
      expect(TokenDispersalWorker).not_to have_received(:perform_async).with(team6.id)
    end
  end
end
