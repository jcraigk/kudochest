require 'rails_helper'

RSpec.describe StreakRewardService do
  subject(:service) { described_class.call(profile:, event_ts:) }

  let(:team) { create(:team, enable_streaks:) }
  let(:profile) { create(:profile, team:) }
  let(:event_ts) { Time.current.to_f.to_s }
  let(:current_time) { Time.zone.local(2019, 11, 5) }

  before { travel_to(current_time) }

  context 'when team.enable_streaks? is false' do
    let(:enable_streaks) { false }

    it 'returns false' do
      expect(service).to be(false)
    end
  end

  context 'when team.enable_streaks? is true' do
    let(:enable_streaks) { true }

    context 'when today is not next streak day' do
      it 'returns false' do
        expect(service).to be(false)
      end
    end

    context 'when next streak day is in the past' do
      it 'resets streak_count and streak_date' do
        service
        expect(profile.reload.streak_count).to eq(1)
        expect(profile.reload.streak_date).to eq(current_time.to_date)
      end

      it 'returns false' do
        expect(service).to be(false)
      end
    end

    context 'when today is next streak day' do
      before do
        profile.streak_count = 2
        profile.streak_date = current_time.to_date - 1.day
      end

      it 'updates profile.streak_count' do
        service
        expect(profile.reload.streak_count).to eq(3)
      end

      context 'when new streak count is >= team.streak_duration' do
        let(:expected_args) do
          {
            from_profile: app_profile,
            to_profile: profile,
            quantity: team.streak_reward,
            event_ts:,
            source: 'streak'
          }
        end
        let!(:app_profile) { create(:profile, team:, rid: team.app_profile_rid) }

        before do
          allow(Tip).to receive(:create!)
          profile.streak_count = 5
        end

        it 'creates a reward tip and returns true' do
          expect(service).to be(true)
          expect(Tip).to have_received(:create!).with(expected_args)
        end
      end
    end
  end
end
