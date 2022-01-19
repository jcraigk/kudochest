# frozen_string_literal: true
require 'rails_helper'

RSpec.shared_examples 'ChannelMemberService' do
  subject(:service) { described_class.call(team:, channel_rid: channel.rid) }

  let(:team) { create(:team, :with_profiles) }
  let(:channel) { create(:channel) }

  context 'when all profiles have been synced' do
    let(:expected_profiles) { team.profiles.sort_by(&:display_name) }

    it 'returns active local profiles sorted by display_name' do
      expect(service).to eq(expected_profiles)
    end
  end
end
