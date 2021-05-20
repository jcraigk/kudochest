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
      include_streak_karma: '1',
      include_imported_karma: '1',
      style: 'split_pot',
      pot_size: 100,
      karma_point_value: 2
    }
  end
  let(:args) do
    params.merge(
      team: team,
      include_streak_karma: true,
      include_imported_karma: true
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
