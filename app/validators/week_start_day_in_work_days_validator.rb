# frozen_string_literal: true
class WeekStartDayInWorkDaysValidator < ActiveModel::Validator
  def validate(record)
    return if record.week_start_day.in?(record.work_days)
    record.errors.add(:week_start_day, :must_be_working_day)
  end
end
