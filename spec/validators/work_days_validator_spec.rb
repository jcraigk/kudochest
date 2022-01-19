# frozen_string_literal: true
require 'rails_helper'

RSpec.describe WorkDaysValidator do
  subject(:validate) { described_class.new.validate(team) }

  let(:team) { build(:team) }

  it 'is valid when there is at least one work day specified' do
    validate
    expect(team.errors).to be_empty
  end

  context 'when no work days specified' do
    let(:team) { build(:team, work_days: []) }

    it 'is invalid' do
      validate
      expect(team.errors[:work_days]).to eq \
        [I18n.t('activerecord.errors.models.team.attributes.work_days.at_least_one')]
    end
  end
end
