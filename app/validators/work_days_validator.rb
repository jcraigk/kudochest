# frozen_string_literal: true
class WorkDaysValidator < ActiveModel::Validator
  def validate(record)
    return if record.work_days.any?
    record.errors.add(:work_days, :at_least_one)
  end
end
