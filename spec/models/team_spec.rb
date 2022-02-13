# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Team do
  subject(:team) { create(:team) }

  it { is_expected.to be_a(ApplicationRecord) }
  it { is_expected.to be_a(Sluggi::Slugged) }

  it do
    expect(team)
      .to belong_to(:owning_user)
      .class_name('User').with_foreign_key(:owner_user_id).inverse_of(:owned_teams)
  end

  it { is_expected.to have_many(:channels).dependent(:destroy) }
  it { is_expected.to have_many(:profiles).dependent(:destroy) }
  it { is_expected.to have_many(:subteams).dependent(:destroy) }
  it { is_expected.to have_many(:topics).dependent(:destroy) }
  it { is_expected.to have_many(:rewards).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:platform) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:rid) }
  it { is_expected.to validate_uniqueness_of(:rid) }
  it { is_expected.to validate_uniqueness_of(:api_key) }
  it { is_expected.to validate_presence_of(:avatar_url) }
  it { is_expected.to validate_numericality_of(:action_hour).is_greater_than_or_equal_to(0) }
  it { is_expected.to validate_numericality_of(:action_hour).is_less_than_or_equal_to(23) }
  it { is_expected.to validate_numericality_of(:token_quantity).is_greater_than_or_equal_to(1) }

  it do
    expect(team)
      .to validate_numericality_of(:token_quantity)
      .is_less_than_or_equal_to(App.max_token_quantity)
  end

  it { is_expected.to validate_numericality_of(:max_points_per_tip).is_greater_than_or_equal_to(1) }

  it do
    expect(team)
      .to validate_numericality_of(:max_points_per_tip)
      .is_less_than_or_equal_to(App.max_points_per_tip)
  end

  it { is_expected.to validate_numericality_of(:token_max).is_greater_than_or_equal_to(1) }

  it do
    expect(team)
      .to validate_numericality_of(:token_max)
      .is_less_than_or_equal_to(App.max_token_max)
  end

  it { is_expected.to validate_numericality_of(:max_level).is_greater_than_or_equal_to(10) }
  it { is_expected.to validate_numericality_of(:max_level).is_less_than_or_equal_to(99) }
  it { is_expected.to validate_numericality_of(:max_level_points).is_greater_than_or_equal_to(100) }
  it { is_expected.to validate_numericality_of(:max_level_points).is_less_than_or_equal_to(10_000) }

  it do
    expect(team)
      .to validate_numericality_of(:streak_duration)
      .is_greater_than_or_equal_to(App.min_streak_duration)
  end

  it do
    expect(team)
      .to validate_numericality_of(:streak_duration)
      .is_less_than_or_equal_to(App.max_streak_duration)
  end

  it { is_expected.to validate_numericality_of(:streak_reward).is_greater_than_or_equal_to(1) }

  it do
    expect(team)
      .to validate_numericality_of(:streak_reward)
      .is_less_than_or_equal_to(App.max_streak_reward)
  end

  describe 'self.bust_cache' do
    let(:mock_cache) { instance_spy(Cache::TeamConfig) }

    before do
      allow(Cache::TeamConfig).to receive(:new).with(team.platform, team.rid).and_return(mock_cache)
      allow(mock_cache).to receive(:delete)
      described_class.bust_cache
    end

    it 'calls Cache::TeamConfig.new' do
      expect(mock_cache).to have_received(:delete)
    end
  end

  describe 're-activation' do
    subject(:team) { create(:team, active: false) }

    before do
      allow(ChannelSyncWorker).to receive(:perform_async)
      allow(TeamSyncWorker).to receive(:perform_async)
      team.update(active: true)
    end

    it 'calls ChannelSyncWorker' do
      expect(ChannelSyncWorker).to have_received(:perform_async).with(team.rid)
    end

    it 'calls TeamSyncWorker' do
      expect(TeamSyncWorker).to have_received(:perform_async).with(team.rid, false)
    end
  end

  describe 'custom validators' do
    let(:validators) { described_class.validators.map(&:class) }
    let(:expected_validators) do
      [
        EmojiQuantityValidator,
        RequireTopicValidator,
        TokenQuantityWithinTokenMaxValidator,
        WeekStartDayInWorkDaysValidator,
        WorkDaysValidator
      ]
    end

    it 'validates with expected validators' do
      expect(validators).to include(*expected_validators)
    end
  end

  it 'sets default work_days and week_start_day' do
    expect(team.work_days).to eq(%w[monday tuesday wednesday thursday friday])
    expect(team.week_start_day).to eq('monday')
  end

  describe '#active scope' do
    let(:active_team) { create(:team) }

    before { create(:team, active: false) }

    it 'returns only active teams' do
      expect(described_class.active).to eq([active_team])
    end
  end

  describe 'slug' do
    subject(:team) { create(:team, name:) }

    let(:name) { 'My Team' }

    it 'creates the slug from parameterized name' do
      expect(team.slug).to eq('my-team')
    end

    context 'with a name that produces a conflicting slug' do
      before { create(:team, name:) }

      it 'creates the slug from parameterized name with random suffix' do
        expect(team.slug).to match(/my-team-[a-f0-9]{6}/)
      end
    end
  end

  describe 'work days=' do
    before { team.work_days = %w[monday tuesday wednesday] }

    it 'stores days as bitmask in work_days_mask' do
      expect(team.work_days_mask).to eq(14)
    end
  end

  describe 'work days' do
    before { team.work_days_mask = 71 }

    it 'provides work_days=' do
      expect(team.work_days).to eq(%w[sunday monday tuesday saturday])
    end
  end

  describe '#bust_cache' do
    let(:mock_cache) { instance_spy(Cache::TeamConfig) }

    before do
      allow(Cache::TeamConfig).to receive(:new).with(team.platform, team.rid).and_return(mock_cache)
      allow(mock_cache).to receive(:delete)
      team.bust_cache
    end

    it 'calls delete on Cache::TeamConfig instance' do
      expect(mock_cache).to have_received(:delete)
    end
  end

  describe 'Cache::TeamConfig cache busting' do
    let(:config) { instance_spy(Cache::TeamConfig) }
    let(:platform) { team.platform }

    shared_examples 'cache busting' do
      it 'calls Cache::TeamConfig.delete' do
        expect(config).to have_received(:delete)
      end
    end

    before do
      allow(Cache::TeamConfig).to receive(:new).with(platform, team.rid).and_return(config)
      allow(config).to receive(:delete)
    end

    describe 'cache busting on platform update' do
      let(:platform) { 'discord' }

      before { team.update(platform:) }

      include_examples 'cache busting'
    end

    describe 'cache busting on api_key update' do
      before { team.update(api_key: 'new-key') }

      include_examples 'cache busting'
    end

    describe 'cache busting on response_mode update' do
      before { team.update(response_mode: 'direct') }

      include_examples 'cache busting'
    end

    describe 'cache busting on log_channel_rid update' do
      before do
        allow(Slack::ChannelJoinService).to receive(:call)
        team.update(log_channel_rid: 'C7KW9GV')
      end

      include_examples 'cache busting'
    end

    describe 'cache busting on active update' do
      before { team.update(active: false) }

      include_examples 'cache busting'
    end

    describe 'cache busting on max_points_per_tip update' do
      before { team.update(max_points_per_tip: 2) }

      include_examples 'cache busting'
    end

    describe 'cache busting on tip_notes update' do
      before { team.update(tip_notes: 'disabled') }

      include_examples 'cache busting'
    end

    describe 'cache busting on app_profile_rid update' do
      before { team.update(app_profile_rid: 'OTHER') }

      include_examples 'cache busting'
    end
  end

  describe 'when activating tip throttling' do
    subject(:team) { create(:team, :with_profiles, throttle_tips: false) }

    before do
      team.profiles.each { |profile| profile.update(points_sent: 10, tokens_accrued: 300) }
      allow(TokenResetWorker).to receive(:perform_async)
      team.update(throttle_tips: true)
    end

    it 'calls TokenRessetWorker' do
      expect(TokenResetWorker).to have_received(:perform_async).with(team.id)
    end
  end

  describe '#next_tokens_at' do
    before { allow(NextIntervalService).to receive(:call) }

    it 'calls NextIntervalService' do
      team.next_tokens_at
      expect(NextIntervalService).to have_received(:call).with \
        team:, attr: :token_frequency, start_at: team.tokens_disbursed_at
    end
  end

  describe '#next_hint_at' do
    before { allow(NextIntervalService).to receive(:call) }

    it 'calls NextIntervalService' do
      team.next_hint_at
      expect(NextIntervalService).to have_received(:call).with \
        team:, attr: :hint_frequency, start_at: team.hint_posted_at
    end
  end

  describe 'app_profile' do
    let!(:profile) { create(:profile, team:, rid: team.app_profile_rid) }

    it 'returns the expected profile' do
      expect(team.app_profile).to eq(profile)
    end
  end

  describe 'joins log_channel on change (Slack only)' do
    let(:channel) { create(:channel, team:) }

    before do
      allow(Slack::ChannelJoinService).to receive(:call)
      team.update(platform: :slack, log_channel_rid: channel.rid)
    end

    it 'calls Slack::ChannelJoinService' do
      expect(Slack::ChannelJoinService)
        .to have_received(:call).with(team:, channel_rid: channel.rid)
    end
  end

  xdescribe 'sync_topic_attrs' do
  end
end
