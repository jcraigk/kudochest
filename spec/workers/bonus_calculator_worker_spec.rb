# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BonusCalculatorWorker do
  subject(:perform) { described_class.new.perform(params.to_json) }

  let(:team) { create(:team) }
  let(:params) do
    {
      team_id: team.id,
      start_date: '2020-10-10',
      end_date: '2020-10-10',
      include_streak_points: '1',
      include_imported_points: '1',
      style: 'split_pot',
      pot_size: 100,
      dollar_per_point: 2
    }
  end
  let(:args) do
    params.merge(
      team:,
      include_streak_points: true,
      include_imported_points: true
    )
  end

  before do
    allow(Team).to receive(:find).with(team.id).and_return(team)
    allow(BonusCalculatorService).to receive(:call)
    perform
  end

  it 'calls BonusCalculatorService' do
    expect(BonusCalculatorService).to have_received(:call).with(args)
  end
end
