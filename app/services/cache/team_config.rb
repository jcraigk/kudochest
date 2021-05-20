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
    Team::CACHED_ATTRS.each_with_object(hash) do |attr, h|
      value = h[attr]
      h[attr] =
        case Team.columns_hash[attr].type
        when :integer then value.to_i
        when :decimal then BigDecimal(value.presence || 0)
        else value; end
    end
  end

  def coerced_cache_result
    coerce_values(fetch_or_cache_team_config)
  end

  def fetch_or_cache_team_config
    JSON.parse(cached_json, object_class: OpenStruct)
  end

  def cached_json
    Rails.cache.fetch(cache_key) { json_data }
  end

  def attr_data
    team.attributes.slice(*Team::CACHED_ATTRS)
  end

  def topic_data
    {
      topics: Topic.active.where(team: team).order(name: :asc).map do |topic|
        topic.slice(:id, :name, :keyword, :emoji)
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
