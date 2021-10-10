# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Reports::TeamDigestService do
  subject(:service) { described_class.call(team: team) }

  let(:team) { create(:team) }
  let(:keys) do
    %i[
      team points_sent num_participants points_from_streak levelup_sentence
      top_recipients top_givers loot_claims_sentence
    ]
  end

  # TODO: test for expected data given a history of tips
  it 'returns expected keys' do
    expect(service.to_h.keys).to eq(keys)
  end
end
