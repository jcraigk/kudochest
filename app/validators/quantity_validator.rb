# frozen_string_literal: true
class QuantityValidator < ActiveModel::Validator
  include KarmaHelper

  attr_reader :record

  def validate(record)
    @record = record

    return if record.source.import? && !absent? # Imports are exempt from max/increment
    return unless absent? || exceeds_max? || invalid_increment?
    record.errors.add(:quantity, error_msg)
  end

  private

  def error_msg
    <<~TEXT.chomp
      must be an increment of #{karma_format(increment)} and a maximum of #{App.max_karma_per_tip}
    TEXT
  end

  def increment
    @increment ||= record.from_profile&.team&.karma_increment || 1
  end

  def invalid_increment?
    (record.quantity % increment).positive?
  end

  def exceeds_max?
    record.quantity > App.max_karma_per_tip
  end

  def absent?
    !record.quantity.positive?
  end
end
