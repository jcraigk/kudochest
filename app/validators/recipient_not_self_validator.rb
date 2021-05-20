# frozen_string_literal: true
class RecipientNotSelfValidator < ActiveModel::Validator
  def validate(record)
    return if record.to_profile_id != record.from_profile_id
    record.errors.add(:base, :cannot_tip_self)
  end
end
