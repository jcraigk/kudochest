class QuantityCoversClaimCountValidator < ActiveModel::Validator
  def validate(record)
    return if record.auto_fulfill || record.quantity >= record.claims.count
    record.errors.add(:quantity, :at_least_claim_count)
  end
end
