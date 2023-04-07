# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Topic do
  subject(:topic) { build(:topic) }

  it { is_expected.to be_a(ApplicationRecord) }

  it { is_expected.to belong_to(:team) }
  it { is_expected.to have_many(:tips).dependent(:nullify) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:team_id) }
  it { is_expected.to validate_uniqueness_of(:emoji).scoped_to(:team_id) }
  it { is_expected.to validate_presence_of(:keyword) }
  it { is_expected.to validate_uniqueness_of(:keyword).scoped_to(:team_id) }
  it { is_expected.to validate_length_of(:keyword).is_at_least(2).is_at_most(20) }

  describe 'keyword format validation' do
    shared_examples 'invalid' do
      before do
        topic.keyword = keyword
        topic.validate
      end

      it 'is invalid' do
        expect(topic.errors[:keyword]).to eq(['must be in snake_case format'])
      end
    end

    context 'when starting with non-letter' do
      let(:keyword) { '1234' }

      include_examples 'invalid'
    end

    context 'when containing invalid chars' do
      let(:keyword) { 'a9YaP' }

      include_examples 'invalid'
    end
  end

  describe 'scopes' do
    let(:topic1) { create(:topic, active: true) }
    let(:topic2) { create(:topic, active: true) }
    let(:topic3) { create(:topic, active: false) }
    let(:topic4) { create(:topic, active: false) }
    let(:active_topics) { [topic1, topic2] }
    let(:inactive_topics) { [topic3, topic4] }

    describe '#active' do
      it 'returns only active topics' do
        expect(described_class.active).to eq(active_topics)
      end
    end

    describe '#inactive' do
      it 'returns only inactive topics' do
        expect(described_class.inactive).to eq(inactive_topics)
      end
    end

    describe '#search' do
      let(:keyword) { 'triforce' }
      let!(:topic1) { create(:topic, name: "#{keyword} blah blah") }
      let!(:topic2) { create(:topic, description: "blah#{keyword}blah") }

      before { create(:topic, name: 'Nutn') }

      it 'returns expected records' do
        expect(described_class.search(keyword)).to contain_exactly(topic1, topic2)
      end
    end
  end

  describe 'team update change' do
    let(:team) { topic.team }

    before do
      topic.save
      allow(team).to receive(:bust_cache)
    end

    describe 'team cache busting' do
      before do
        topic.update(name: 'New name')
      end

      it 'busts team cache when creating a topic' do
        expect(team).to have_received(:bust_cache)
      end
    end

    describe 'team.require_topic' do
      before do
        team.update(require_topic: true)
      end

      context 'when there are no active topics' do
        before do
          topic.update(active: false)
        end

        it 'disables require_topic' do
          expect(team.require_topic).to be(false)
        end
      end
    end
  end
end
