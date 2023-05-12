class RequireTopicValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    return if !record.require_topic? || record.topics.active.any?
    record.errors.add(:require_topic, 'can be enabled only when there are active topics')
  end
end
