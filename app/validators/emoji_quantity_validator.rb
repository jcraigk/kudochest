class EmojiQuantityValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    return if (record.emoji_quantity % record.tip_increment).zero?

    record.errors.add \
      :emoji_quantity,
      "must be a multiple of the #{App.points_term.titleize} Increment (#{record.tip_increment})"
  end
end
