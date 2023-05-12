require 'rails_helper'

class Slack::FooService; end # rubocop:disable Lint/EmptyClass

RSpec.describe ConstService do
  subject(:service) { described_class.call(platform, klass) }

  let(:platform) { 'slack' }
  let(:klass) { 'FooService' }

  it 'constantizes the composition of platform and klass' do
    expect(service).to eq(Slack::FooService)
  end
end
