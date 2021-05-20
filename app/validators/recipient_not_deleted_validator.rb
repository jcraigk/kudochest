# frozen_string_literal: true
class RecipientNotDeletedValidator < ActiveModel::Validator
  def validate(record)
    return unless record.to_profile&.deleted?
    record.errors.add(:base, :cannot_tip_deleted)
  end
end
