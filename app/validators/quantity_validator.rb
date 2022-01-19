# frozen_string_literal: true
class QuantityValidator < ActiveModel::Validator
  include PointsHelper

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
      must be an increment of #{points_format(increment)} and a maximum of #{points_format(team.max_points_per_tip)}
    TEXT
  end

  def increment
    @increment ||= record.from_profile&.team&.tip_increment || 1
  end

  def invalid_increment?
    (record.quantity % increment).positive?
  end

  def exceeds_max?
    record.quantity > max_quantity
  end

  def max_quantity
    team&.max_points_per_tip || App.max_points_per_tip
  end

  def absent?
    !record.quantity.positive?
  end

  def team
    @team ||= record.from_profile&.team
  end
end
