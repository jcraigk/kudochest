# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Commands::Undo, :freeze_time do
  subject(:command) { described_class.call(team_rid: profile.team.rid, profile_rid: profile.rid) }

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team:) }

  shared_examples 'expected response' do
    it 'returns stats text' do
      expect(command).to eq(response)
    end
  end

  context 'when no undoable tip exists' do
    let(:text) { ":#{App.error_emoji}: Nothing to undo" }
    let(:response) { ChatResponse.new(mode: :error, text:) }

    include_examples 'expected response'
  end

  context 'when an older undoable tip exists' do
    let(:text) { ":#{App.error_emoji}: Nothing to undo" }
    let(:response) { ChatResponse.new(mode: :error, text:) }

    before do
      create \
        :tip,
        from_profile: profile,
        created_at: Time.current - App.undo_cutoff - 1.minute
    end

    include_examples 'expected response'
  end

  context 'when a recent undoable tip exists' do
    let(:recipient) { create(:profile, team:) }
    let(:text) { "You revoked #{points_format(1, label: true)} from #{recipient.link}" }
    let(:response) { ChatResponse.new(mode: :private, text:) }

    before do
      create \
        :tip,
        from_profile: profile,
        to_profile: recipient,
        created_at: Time.current - App.undo_cutoff + 1.minute
    end

    include_examples 'expected response'
  end

  context 'with a multi-recipient and streak reward situation' do
    let(:ts) { Time.current.to_f.to_s }
    let(:recipient1) { create(:profile, team:) }
    let(:recipient2) { create(:profile, team:) }
    let(:text) do
      <<~TEXT.chomp
        You revoked #{points_format(2, label: true)} from #{recipient2.link} and #{points_format(1, label: true)} from #{recipient1.link}
      TEXT
    end
    let(:response) { ChatResponse.new(mode: :private, text:) }
    let(:app_profile) { create(:profile, team:, rid: team.app_profile_rid) }
    let(:created_at) { Time.current - App.undo_cutoff + 1.minute }

    before do
      create \
        :tip,
        from_profile: profile,
        to_profile: recipient1,
        created_at:,
        event_ts: ts
      create \
        :tip,
        from_profile: profile,
        to_profile: recipient2,
        quantity: 2,
        created_at:,
        event_ts: ts
      create \
        :tip,
        from_profile: app_profile,
        to_profile: profile,
        source: 'streak',
        quantity: 2,
        created_at:,
        event_ts: ts
    end

    include_examples 'expected response'

    xit 'if many recipients, mentions "4 users" instead of "a, b, and c"' do
    end
  end
end
