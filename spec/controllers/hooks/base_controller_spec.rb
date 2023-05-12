require 'rails_helper'

describe Hooks::BaseController do
  include Rack::Test::Methods

  xcontext 'when inherited and used in a child controller' do
    subject(:response) { post(hooks_slack_event_path, params) }

    let(:slack_request) { instance_spy(Slack::Events::Request) }
    let(:params) { { event: { foo: 'bar' } } }
    let(:result) { ChatResponse.new(mode: :foo, text: 'bar') }

    before do
      allow(Slack::PostService).to receive(:call)
      allow(SlackEventDispatch).to receive(:call).and_return(result)
      allow(Slack::Events::Request).to receive(:new).and_return(slack_request)
      allow(slack_request).to receive(:verify!)
    end

    # it 'skips require_login' do
    # end
    #
    # it 'skips verify_authenticity_token' do
    # end
  end
end
