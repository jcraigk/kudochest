# frozen_string_literal: true
class RecipientNotSelfValidator < ActiveModel::Validator
  def validate(record)
    return if record.to_profile_id != record.from_profile_id
    record.errors.add(
      :base,
      I18n.t(
        'activerecord.errors.models.tip.attributes.base.cannot_tip_self',
        user: record.from_profile&.link,
        points: App.points_term
      ).squish
    )
  end
end
