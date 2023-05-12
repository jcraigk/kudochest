require 'rails_helper'

RSpec.describe Actions::AppUninstalled do
  subject(:action) { described_class.call(**params) }

  let!(:team) { create(:team) }

  let(:params) { { team_rid: team.rid } }

  before do
    action
  end

  it 'deactivates the team' do
    expect(team.reload.active?).to be(false)
    expect(team.reload.installed?).to be(false)
  end
end
