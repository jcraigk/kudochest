require 'rails_helper'

describe Hooks::Slack::ActionsController do
  include Rack::Test::Methods

  subject(:response) { post(hooks_slack_action_path, params) }

  include_context 'with Slack request verification and active team' do
    let(:team) { team }
  end

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team:) }
  let(:params) do
    {
      payload: {
        callback_id: 'reply_tip',
        team: {
          id: team.rid
        },
        user: {
          id: profile.rid
        }
      }.to_json
    }
  end

  before do
    allow(Slack::PostService).to receive(:call).and_return({ 'ts' => :foo })
    allow(EventWorker).to receive(:perform_async)
  end

  it 'calls EventWorker' do
    expect(response).to be_ok
    expect(EventWorker).to have_received(:perform_async)
  end
end
