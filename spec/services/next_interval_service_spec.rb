require 'rails_helper'

RSpec.describe NextIntervalService do
  subject(:service) do
    described_class.call(team:, attr:, start_at:)
  end

  let(:team) { create(:team) }
  let(:start_at) { nil }

  before do
    travel_to(Time.zone.local(2019, 11, 5))
  end

  shared_examples 'expected time' do
    it 'returns expected time' do
      expect(service.to_s).to eq(timestamp)
    end
  end

  context 'when attr is :token_frequency' do
    let(:team) { create(:team, token_frequency:) }
    let(:attr) { :token_frequency }
    let(:start_at) { Time.current }

    context 'when token_frequency is :daily' do
      let(:token_frequency) { :daily }
      let(:timestamp) { '2019-11-05 07:00:00 UTC' }

      include_examples 'expected time'
    end

    context 'when token_frequency is :weekly' do
      let(:token_frequency) { :weekly }
      let(:timestamp) { '2019-11-11 07:00:00 UTC' }

      include_examples 'expected time'
    end

    context 'when token_frequency is :monthly' do
      let(:token_frequency) { :monthly }
      let(:timestamp) { '2019-12-01 07:00:00 UTC' }

      include_examples 'expected time'
    end

    context 'when token_frequency is :quarterly' do
      let(:token_frequency) { :quarterly }
      let(:timestamp) { '2020-01-01 07:00:00 UTC' }

      include_examples 'expected time'
    end

    context 'when token_frequency is :yearly' do
      let(:token_frequency) { :yearly }
      let(:timestamp) { '2020-01-01 07:00:00 UTC' }

      include_examples 'expected time'
    end

    context 'when start_at is provided' do
      let(:token_frequency) { :weekly }
      let(:start_at) { Time.zone.local(2019, 1, 1) }
      let(:timestamp) { '2019-01-07 07:00:00 UTC' }

      include_examples 'expected time'
    end
  end
end
