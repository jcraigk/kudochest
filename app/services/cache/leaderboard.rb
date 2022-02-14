# frozen_string_literal: true
class Cache::Leaderboard < Base::Service
  param :team_id
  param :giving_board, default: -> { false }
  param :jab_board, default: -> { false }

  def get
    return if redis_value.blank?
    LeaderboardPage.new(updated_at, profiles)
  end

  def set(value)
    RedisClient.set(key, value.to_json)
  end

  private

  def updated_at
    data[:updated_at]
  end

  def profiles
    data[:profiles].map { |p| LeaderboardProfile.new(p) }
  end

  def data
    @data ||= JSON.parse(redis_value, symbolize_names: true)
  end

  def redis_value
    @redis_value ||= RedisClient.get(key)
  end

  def key
    "leaderboard/#{team_id}/#{style}/#{action}"
  end

  def action
    giving_board ? 'sent' : 'received'
  end

  def style
    jab_board ? 'jabs' : 'points'
  end
end
