# frozen_string_literal: true
class EmojiQuantityValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    return if (record.emoji_quantity % record.karma_increment).zero?

    record.errors.add(
      :emoji_quantity,
      "must be a multiple of the #{App.points_term.titleize} Increment (#{record.karma_increment})"
    )
  end
end
