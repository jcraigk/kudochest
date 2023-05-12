require 'rails_helper'

RSpec.describe TipHistogramService do
  subject(:call) { described_class.call(profile:, user:, limit: 5) }

  let!(:profile) { create(:profile) }
  let(:user) { build(:user) }
  let(:color) { '#000000' }
  let(:library) do
    {
      datalabels: {
        align: 'top',
        anchor: 'end',
        color:
      }
    }
  end

  before do
    travel_to(Time.zone.local(2019, 11, 5))
  end

  shared_examples 'expected result' do
    it 'returns expected resultset' do
      expect(call).to eq(expected_result)
    end
  end

  xcontext 'when user theme is dark' do
    it 'colors labels white' do
    end
  end

  context 'when no points have been given or earned' do
    let(:expected_result) do
      [
        {
          name: "#{App.points_term.titleize} Given",
          data: {
            'Nov 1' => 0,
            'Nov 2' => 0,
            'Nov 3' => 0,
            'Nov 4' => 0,
            'Nov 5' => 0
          },
          library:
        },
        {
          name: "#{App.points_term.titleize} Received",
          data: {
            'Nov 1' => 0,
            'Nov 2' => 0,
            'Nov 3' => 0,
            'Nov 4' => 0,
            'Nov 5' => 0
          },
          library:
        }
      ]
    end

    include_examples 'expected result'
  end

  context 'when points have been given and earned' do
    let(:expected_result) do
      [
        {
          name: "#{App.points_term.titleize} Given",
          data: {
            'Nov 1' => 0,
            'Nov 2' => 2,
            'Nov 3' => 5,
            'Nov 4' => 0,
            'Nov 5' => 0
          },
          library:
        },
        {
          name: "#{App.points_term.titleize} Received",
          data: {
            'Nov 1' => 0,
            'Nov 2' => 2,
            'Nov 3' => 0,
            'Nov 4' => 1,
            'Nov 5' => 2
          },
          library:
        }
      ]
    end

    before do
      create(:tip, created_at: Time.zone.local(2019, 11, 2), from_profile: profile)
      create(:tip, created_at: Time.zone.local(2019, 11, 2), from_profile: profile)
      create(:tip, created_at: Time.zone.local(2019, 11, 3), from_profile: profile, quantity: 5)
      create(:tip, created_at: Time.zone.local(2019, 11, 2), to_profile: profile, quantity: 2)
      create(:tip, created_at: Time.zone.local(2019, 11, 4), to_profile: profile)
      create(:tip, created_at: Time.zone.local(2019, 11, 5), to_profile: profile)
      create(:tip, created_at: Time.zone.local(2019, 11, 5), to_profile: profile)
    end

    include_examples 'expected result'
  end
end
