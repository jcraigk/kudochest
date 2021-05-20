# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Actions::Base do
  let(:params) do
    {
      foo: 'bar',
      callback_id: 'baz'
    }
  end

  it 'calls `#new(params)` on self' do
    allow(described_class).to receive(:new).and_call_original
    described_class.call(params)
    expect(described_class).to have_received(:new).with(params)
  end

  it 'exposes #call as self.call' do
    expect(described_class.call(params)).to eq('Override in child class')
  end
end
