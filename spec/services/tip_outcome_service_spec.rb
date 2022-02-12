# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TipOutcomeService, :freeze_time do
  subject(:call) { described_class.call(tips:, destroy:) }

  let(:team) { create(:team) }
  let(:from_profile) { create(:profile, team:) }
  let(:tips) { [tip1, tip2, tip3, tip4] }
  let(:tip1) { create(:tip, from_profile:, to_profile: recipient1, quantity: 2) }
  let(:tip2) { create(:tip, from_profile:, to_profile: recipient1, quantity: -5) }
  let(:tip3) { create(:tip, from_profile:, to_profile: recipient2, quantity: 1) }
  let(:tip4) { create(:tip, from_profile:, to_profile: recipient2, quantity: -3) }
  let(:recipient1) { create(:profile, team:) }
  let(:recipient2) { create(:profile, team:) }
  let(:destroy) { nil }

  before do
    allow(LeaderboardRefreshWorker).to receive(:perform_async)
  end

  it 'calls LeaderboardRefreshWorker' do
    call
    expect(LeaderboardRefreshWorker).to have_received(:perform_async).with(team.id)
    expect(LeaderboardRefreshWorker).to have_received(:perform_async).with(team.id, true)
  end

  context 'when creating tips' do
    let(:destroy) { false }

    before { call }

    it 'increments recipient1 stats' do
      recipient1.reload
      expect(recipient1.points_received).to eq(2)
      expect(recipient1.jabs_received).to eq(5)
      expect(recipient1.balance).to eq(-3)
      expect(recipient1.last_tip_received_at).to eq(Time.current)
    end

    it 'increments recipient2 stats' do
      recipient2.reload
      expect(recipient2.points_received).to eq(1)
      expect(recipient2.jabs_received).to eq(3)
      expect(recipient2.balance).to eq(-2)
      expect(recipient2.last_tip_received_at).to eq(Time.current)
    end

    it 'increments sender stats' do
      from_profile.reload
      expect(from_profile.points_sent).to eq(3)
      expect(from_profile.jabs_sent).to eq(8)
      expect(from_profile.last_tip_sent_at).to eq(Time.current)
    end

    it 'increments the team stats' do
      team.reload
      expect(team.points_sent).to eq(3)
      expect(team.jabs_sent).to eq(8)
      expect(team.balance).to eq(-5)
    end
  end

  context 'when destroy tips' do
    # In the future so we don't actually have to delete the tips we're processing
    let(:previous_sent_at) { DateTime.new(2223, 1, 1) }
    let(:previous_received_at1) { DateTime.new(2224, 1, 1) }
    let(:previous_received_at2) { DateTime.new(2225, 1, 1) }
    let(:destroy) { true }

    # rubocop:disable Rails/SkipsModelValidations
    before do
      create(:tip, to_profile: recipient1).update_column(:created_at, previous_received_at1)
      create(:tip, to_profile: recipient2).update_column(:created_at, previous_received_at2)
      create(:tip, from_profile:).update_column(:created_at, previous_sent_at)
      call
    end
    # rubocop:enable Rails/SkipsModelValidations

    it 'decrements recipient1 stats and resets timestamp' do
      recipient1.reload
      expect(recipient1.points_received).to eq(-2)
      expect(recipient1.jabs_received).to eq(-5)
      expect(recipient1.balance).to eq(3)
      expect(recipient1.last_tip_received_at).to eq(previous_received_at1)
    end

    it 'decrements recipient2 stats and resets timestamp' do
      recipient2.reload
      expect(recipient2.points_received).to eq(-1)
      expect(recipient2.jabs_received).to eq(-3)
      expect(recipient2.balance).to eq(2)
      expect(recipient2.last_tip_received_at).to eq(previous_received_at2)
    end

    it 'decrements sender stats and resets timestamp' do
      from_profile.reload
      expect(from_profile.points_sent).to eq(-3)
      expect(from_profile.jabs_sent).to eq(-8)
      expect(from_profile.last_tip_sent_at).to eq(previous_sent_at)
    end

    it 'decrements the team stats' do
      team.reload
      expect(team.points_sent).to eq(-3)
      expect(team.jabs_sent).to eq(-8)
      expect(team.balance).to eq(5)
    end

    it 'destroys the tips' do
      expect { tip1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { tip2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { tip3.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { tip4.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
