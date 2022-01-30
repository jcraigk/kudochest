# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EventWorker do
  subject(:perform) { described_class.new.perform(params.to_json) }

  let(:team) { create(:team) }
  let(:params) { { 'foo' => 'bar' } }

  before do
    allow(EventService).to receive(:call)
    perform
  end

  it 'calls service with expected args' do
    expect(EventService).to have_received(:call).with(params: { foo: 'bar' })
  end
end
