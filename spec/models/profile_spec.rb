# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Profile do
  subject(:profile) { create(:profile) }

  it { is_expected.to be_a(ApplicationRecord) }
  it { is_expected.to be_a(Sluggi::Slugged) }
  it { is_expected.to be_a(TokenRegisterable) }

  it { is_expected.to belong_to(:team) }
  it { is_expected.to belong_to(:user).optional }

  it { is_expected.to have_many(:tips_received).dependent(:destroy) }
  it { is_expected.to have_many(:tips_sent).dependent(:destroy) }
  it { is_expected.to have_many(:claims).dependent(:destroy) }

  it { is_expected.to validate_uniqueness_of(:rid).scoped_to(:team_id) }
  it { is_expected.to validate_presence_of(:avatar_url) }
  it { is_expected.to validate_presence_of(:display_name) }
  it { is_expected.to validate_presence_of(:slug) }

  it 'aliases #points to #points_received' do
    expect(profile.points).to eq(profile.points_received)
  end

  describe 'active?' do
    context 'when bot_user is true' do
      before { profile.update(bot_user: true) }

      it 'returns false' do
        expect(profile.active?).to eq(false)
      end
    end

    context 'when deleted is true' do
      before { profile.update(deleted: true) }

      it 'returns false' do
        expect(profile.active?).to eq(false)
      end
    end
  end

  describe '#collection_with_team' do
    let!(:profile) { create(:profile, team:) }
    let!(:profile2) { create(:profile, team:) }
    let(:team) { build(:team) }

    before do
      create(:profile, rid: profile.rid, team: build(:team))
    end

    it 'returns only profiles from given team' do
      expect(described_class.collection_with_team(profile.team.rid, [profile.rid, profile2.rid]))
        .to match_array([profile, profile2])
    end
  end

  describe '#find_with_team' do
    let!(:profile) { create(:profile, team:) }
    let(:team) { build(:team) }

    before do
      create(:profile, rid: profile.rid, team: build(:team))
    end

    it 'returns first profile from given team' do
      expect(described_class.find_with_team(profile.team.rid, profile.rid)).to eq(profile)
    end
  end

  describe 'custom validators' do
    let(:validators) { described_class.validators.map(&:class) }
    let(:expected_validators) { [OneProfilePerTeamPerUserValidator] }

    it 'validates with expected validators' do
      expect(validators).to include(*expected_validators)
    end
  end

  describe '#active scope' do
    let(:active_profile) { create(:profile) }

    before do
      create(:profile, bot_user: true)
      create(:profile, deleted: true)
    end

    it 'returns only active profiles' do
      expect(described_class.active).to eq([active_profile])
    end
  end

  describe '#matching scope' do
    let!(:profile1) { create(:profile, display_name: 'Batman') }
    let!(:profile2) { create(:profile, real_name: 'Batman') }

    before do
      create(:profile, display_name: 'Bob')
      create(:profile, real_name: 'man')
    end

    it 'returns only matching profiles' do
      expect(described_class.matching('atm')).to match_array([profile1, profile2])
    end
  end

  describe 'slug' do
    subject(:profile) { create(:profile, display_name: name, team:) }

    let(:team) { create(:team, name: team_name) }

    let(:team_name) { 'My Team' }
    let(:name) { 'My Profile' }

    it 'creates the slug from parameterized team name and profile name' do
      expect(profile.slug).to eq('my-team-my-profile')
    end

    context 'with a name that produces a conflicting slug' do
      before { create(:profile, display_name: name, team:) }

      it 'creates the slug from parameterized name with random suffix' do
        expect(profile.slug).to match(/my-team-my-profile-[a-f0-9]{6}/)
      end
    end

    describe '#reset_slug!' do
      subject(:profile) { create(:profile) }

      let(:slug) { "#{profile.team.name.parameterize}-#{profile.display_name.parameterize}" }

      it 'resets the slug' do
        profile.reset_slug!
        expect(profile.slug).to eq(slug)
      end
    end
  end

  describe 'team member_count' do
    context 'when updating deleted to true' do
      before { profile.update(deleted: true) }

      it 'updates member_count on parent team' do
        expect(profile.team.member_count).to eq(0)
      end
    end
  end

  describe '#token_balance' do
    before { profile.update(tokens_accrued: 30, points_sent: 20) }

    it 'returns tokens_accrued - points_sent' do
      expect(profile.token_balance).to eq(10)
    end
  end
end
