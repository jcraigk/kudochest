require 'rails_helper'

RSpec.describe Reports::TeamDigestService do
  subject(:service) { described_class.call(team:) }

  let(:team) { create(:team) }
  let(:keys) do
    %i[
      team points_given jabs_given num_givers num_recipients points_from_streak
      point_givers jab_givers point_recipients jab_recipients
      leveling_sentence top_recipients top_givers loot_claims_sentence
    ]
  end

  # TODO: test for expected data given a history of tips
  it 'returns expected keys' do
    expect(service.to_h.keys).to eq(keys)
  end
end
