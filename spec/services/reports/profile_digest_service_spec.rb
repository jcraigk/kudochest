# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Reports::ProfileDigestService do
  subject(:service) { described_class.call(profile:) }

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team:) }
  let(:keys) do
    %i[
      profile points_received num_givers points_sent num_recipients
      points_from_streak levelup_sentence rank_sentence top_recipients
      top_givers
    ]
  end

  # TODO: test for expected data given a history of tips
  it 'returns expected keys' do
    expect(service.to_h.keys).to eq(keys)
  end
end
