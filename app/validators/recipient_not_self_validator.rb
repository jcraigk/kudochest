# frozen_string_literal: true
class RecipientNotSelfValidator < ActiveModel::Validator
  def validate(record)
    return if record.to_profile_id != record.from_profile_id
    key, points = record.quantity.negative? ? [:jab, App.jabs_term] : [:tip, App.points_term]
    record.errors.add \
      :base,
      I18n.t(
        "activerecord.errors.models.tip.attributes.base.cannot_#{key}_self",
        user: record.from_profile&.link,
        points:
      ).squish
  end
end
