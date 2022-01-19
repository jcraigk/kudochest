# frozen_string_literal: true
require 'rails_helper'

RSpec.describe HourlyTeamWorker do
  subject(:perform) { described_class.new.perform }

  # TODO: Adjust timezones on each team, ensure daylight savings works
  # Also ensure travel_to works (seems it was using actual current time)
  let(:current_hour) { Time.current.hour }
  let(:frequency) { 'weekly' }
  let(:mock_relation) { instance_spy(ActiveRecord::Relation) }
  let(:current_time) { Time.zone.local(2019, 11, 8, 21, 1, 1) }
  let!(:team1) { create(:team, throttle_tips: true, action_hour: current_hour) }
  let!(:team2) { create(:team, throttle_tips: true, action_hour: current_hour) }
  let!(:team3) do
    create(
      :team,
      throttle_tips: true,
      token_frequency: 'weekly',
      action_hour: current_hour,
      tokens_disbursed_at: travel_to_time
    )
  end
  let!(:team4) do
    create(
      :team,
      throttle_tips: true,
      token_frequency: 'monthly',
      action_hour: current_hour,
      hint_frequency: 'hourly',
      hint_channel_rid: 'foo'
    )
  end
  let(:travel_to_time) { (1.month.from_now).change(hour: current_hour) }

  before do
    travel_to(current_time)
    allow(TokenDispersalWorker).to receive(:perform_async)
    allow(HintWorker).to receive(:perform_async)
    allow(mock_relation).to receive(:find_each).and_yield(team1).and_yield(team2)
    allow(Team).to receive(:active).and_return(mock_relation)
    allow(mock_relation).to \
      receive(:find_each).and_yield(team1).and_yield(team2).and_yield(team3).and_yield(team4)
    travel_to(travel_to_time)
    perform
  end

  it 'calls TokenDispersalWorker on monthly team once' do
    expect(TokenDispersalWorker).to have_received(:perform_async).with(team4.id)
  end

  it 'calls HintWorker on team4' do
    expect(HintWorker).to have_received(:perform_async).with(team4.id)
  end
end
