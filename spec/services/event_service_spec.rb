# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EventService do
  subject(:service) { described_class.call(params: params) }

  let(:params) do
    {
      platform: 'slack',
      action: 'message',
      channel_rid: 'C012345'
    }
  end

  shared_examples 'success' do
    it 'calls Slack::PostService with expected args' do
      service
      expect(Slack::PostService).to have_received(:call).with(args)
    end
  end

  before do
    allow(Slack::PostService).to receive(:call)
  end

  context 'when an exception occurs and channel_rid is present' do
    let(:text) do
      <<~TEXT.chomp
        :#{App.error_emoji}: Sorry, something went wrong. If the problem persists, please contact support.
      TEXT
    end
    let(:args) do
      params.merge(
        mode: :error,
        text: text
      )
    end

    before { allow(Actions::Message).to receive(:call).and_raise('whoopsy') }

    include_examples 'success'
  end

  context 'without exception' do
    let(:args) { params.merge(result.to_h) }
    let(:result) { ChatResponse.new(mode: :public) }

    before { allow(Actions::Message).to receive(:call).and_return(result) }

    include_examples 'success'
  end
end
