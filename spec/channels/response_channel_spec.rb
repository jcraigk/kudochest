require 'rails_helper'

RSpec.describe ResponseChannel do
  let(:team) { create(:team) }

  it 'successfully subscribes to team stream' do
    stub_connection current_profile_team: team
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(team)
  end
end
