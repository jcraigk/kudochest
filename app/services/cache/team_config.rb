class Cache::TeamConfig < Base::Service
  param :platform
  param :rid

  def call
    cached_data
  end

  def delete
    Rails.cache.delete(cache_key)
  end

  private

  def cached_data
    JSON.parse(cached_json, symbolize_names: true)
        .each_with_object({}) { |(k, v), h| h[k] = coerce_value(k, v) }
  end

  def coerce_value(attr, value)
    case Team.columns_hash[attr.to_s]&.type
    when :integer then value.to_i
    when :decimal then BigDecimal(value.presence || '0')
    else value; end
  end

  def cached_json
    Rails.cache.fetch(cache_key) { json_data }
  end

  def json_data
    team.attributes.slice(*Team::CONFIG_ATTRS).merge(topics: topic_data).to_json
  end

  def topic_data
    team.topics.active.order(name: :asc).map do |topic|
      topic.attributes.slice('id', 'name', 'keyword', 'emoji').symbolize_keys
    end
  end

  def team
    @team ||= Team.includes(:topics).find_by!(platform:, rid:)
  end

  def cache_key
    "config/#{platform}/#{rid}"
  end
end
