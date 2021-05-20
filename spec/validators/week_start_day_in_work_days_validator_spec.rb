# frozen_string_literal: true
require 'rails_helper'

RSpec.describe WeekStartDayInWorkDaysValidator do
  subject(:validate) { described_class.new.validate(team) }

  let(:team) { build(:team) }

  it 'is valid when week_start_day is in work_days' do
    validate
    expect(team.errors).to be_empty
  end

  context 'when week_start_day is not in work_days' do
    let(:team) { build(:team, work_days: %w[tuesday], week_start_day: %w[monday]) }

    it 'is invalid' do
      validate
      expect(team.errors[:week_start_day]).to eq(
        [I18n.t('activerecord.errors.models.team.attributes.week_start_day.must_be_working_day')]
      )
    end
  end
end
