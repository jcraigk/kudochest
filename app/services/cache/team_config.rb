# frozen_string_literal: true
class Cache::TeamConfig < Base::Service
  param :team_rid

  def call
    coerced_cache_result
  end

  def delete
    Rails.cache.delete(cache_key)
  end

  private

  def coerce_values(hash)
    data = TeamConfig.members.each_with_object(hash) do |attr, h|
      h[attr] = coerce_value(attr, h[attr])
    end
    data[:topics] = hash[:topics].map { |topic| TopicData.new(topic) }
    data
  end

  def coerce_value(attr, value)
    case Team.columns_hash[attr.to_s]&.type
    when :integer then value.to_i
    when :decimal then BigDecimal(value.presence || 0)
    else value; end
  end

  def coerced_cache_result
    TeamConfig.new(coerce_values(cached_hash))
  end

  def cached_hash
    JSON.parse(cached_json, symbolize_names: true)
  end

  def cached_json
    Rails.cache.fetch(cache_key) { json_data }
  end

  def attr_data
    team.attributes.slice(*TeamConfig.members.map(&:to_s))
  end

  def topic_data
    {
      topics: Topic.active.where(team:).order(name: :asc).map do |topic|
        topic.attributes.slice(*TopicData.members.map(&:to_s))
      end
    }
  end

  def json_data
    attr_data.merge(topic_data).to_json
  end

  def team
    @team ||= Team.includes(:topics).find_by!(rid: team_rid)
  end

  def cache_key
    "team_response_config/#{team_rid}"
  end
end
