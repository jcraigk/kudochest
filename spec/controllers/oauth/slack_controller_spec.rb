require 'rails_helper'

describe Oauth::SlackController do
  include Rack::Test::Methods
  include Sorcery::TestHelpers::Rails::Request

  subject(:response) { get(oauth_slack_integration_path, params) }

  let(:user) { create(:user) }
  let(:code) { 'abc ' }
  let(:api_key) { 'xyz ' }
  let(:params) { { code: } }
  let(:web_client) { instance_spy(Slack::Web::Client) }
  let(:client_params) do
    {
      client_id: ENV.fetch('SLACK_CLIENT_ID', nil),
      client_secret: ENV.fetch('SLACK_CLIENT_SECRET', nil),
      code:
    }
  end
  let(:team) { build(:team) }
  let(:oauth_data) do
    {
      team_id: team.rid,
      team_name: team.name,
      bot: {
        bot_access_token: api_key
      }
    }
  end
  let(:team_data) do
    {
      rid: team.rid,
      name: team.name,
      owner_user_id: user.id,
      api_key:
    }
  end

  before do
    allow(Slack::Web::Client).to receive(:new).and_return(web_client)
    allow(web_client).to receive(:oauth_access).with(client_params).and_return(oauth_data)
    allow(TeamRegistrar).to receive(:call).and_call_original
    login_user(nil) # TODO: how to login? using header...
  end

  xit 'calls TeamRegistrar and redirects' do
    expect(response).to have_http_status(:found)
    expect(TeamRegistrar).to have_received(:call).with(team_data)
  end
end
