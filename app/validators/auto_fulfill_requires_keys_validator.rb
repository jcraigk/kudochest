class AutoFulfillRequiresKeysValidator < ActiveModel::Validator
  def validate(record)
    return if !auto_fulfill?(record) || record.fulfillment_keys.present?
    record.errors.add(:fulfillment_keys, :must_be_present)
  end

  private

  def auto_fulfill?(record)
    record.auto_fulfill == true || record.auto_fulfill == '1'
  end
end
