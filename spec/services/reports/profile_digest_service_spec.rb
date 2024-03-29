require 'rails_helper'

RSpec.describe Reports::ProfileDigestService do
  subject(:service) { described_class.call(profile:) }

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team:) }
  let(:keys) do
    %i[
      profile points_received jabs_received point_givers jab_givers points_given jabs_given
      point_recipients jab_recipients points_from_streak leveling_sentence rank_sentence
      top_recipients top_givers
    ]
  end

  # TODO: test for expected data given a history of tips
  it 'returns expected keys' do
    expect(service.to_h.keys).to eq(keys)
  end
end
