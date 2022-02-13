# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Commands::Report do
  subject(:command) do
    described_class.call(team_rid: team.rid, profile_rid: profile.rid, text:)
  end

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team:) }

  shared_examples 'success' do
    it 'returns expected title' do
      expect(command.text).to start_with(expected_title)
    end

    # TODO
    # xit 'returns expected details' do
    # end
  end

  before do
    travel_to(Time.zone.local(2019, 11, 8, 21, 1, 1))
  end

  context 'when no profile given, provides team report' do
    let(:text) { '' }
    let(:expected_title) { "*Report for #{team.name} covering Nov 1 - 8*" }

    include_examples 'success'
  end

  context 'when timeframe given, scopes to that timeframe' do
    let(:text) { '100' }
    let(:expected_title) { "*Report for #{team.name} covering Jul 31 - Nov 8*" }

    include_examples 'success'
  end

  context 'when `me` is given, provides profile report' do
    let(:text) { 'me' }
    let(:expected_title) { "*Report for #{profile.dashboard_link} covering Nov 1 - 8*" }

    include_examples 'success'
  end

  context 'when a profile is given, provides profile report' do
    let(:profile2) { create(:profile, team:) }
    let(:text) { profile2.link }
    let(:expected_title) { "*Report for #{profile2.dashboard_link} covering Nov 1 - 8*" }

    include_examples 'success'
  end
end
