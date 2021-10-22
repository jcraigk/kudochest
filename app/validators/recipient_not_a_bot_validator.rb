# frozen_string_literal: true
class RecipientNotABotValidator < ActiveModel::Validator
  def validate(record)
    return unless record.to_profile&.bot_user?
    record.errors.add(
      :base,
      I18n.t(
        "activerecord.errors.models.tip.attributes.base.#{type(record)}",
        user: record.from_profile&.link,
        points: App.points_term
      ).squish
    )
  end

  private

  def type(record)
    if record.to_profile.team.app_profile_rid == record.to_profile.rid
      :cannot_accept_tips
    else
      :cannot_tip_bots
    end
  end
end
