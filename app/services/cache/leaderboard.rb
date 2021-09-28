# frozen_string_literal: true
class Cache::Leaderboard < Base::Service
  param :team_id
  param :givingboard, default: -> { false }

  def get
    return if redis_value.blank?
    JSON.parse(redis_value, object_class: OpenStruct)
  end

  def set(value)
    RedisClient.set(key, value.to_json)
  end

  private

  def redis_value
    @redis_value ||= RedisClient.get(key)
  end

  def key
    "leaderboard/#{team_id}/#{action}"
  end

  def action
    givingboard ? 'sent' : 'received'
  end
end
