class TokenQuantityWithinTokenMaxValidator < ActiveModel::Validator
  def validate(record)
    return if record.token_quantity.to_i <= record.token_max.to_i
    record.errors.add(:token_quantity, :within_token_max)
  end
end
