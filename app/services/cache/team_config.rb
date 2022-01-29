# frozen_string_literal: true
class Cache::TeamConfig < Base::Service
  param :team_rid

  def call
    JSON.parse(cached_json, symbolize_names: true)
  end

  def delete
    Rails.cache.delete(cache_key)
  end

  private

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
    @team ||= Team.includes(:topics).find_by!(rid: team_rid)
  end

  def cache_key
    "team_response_config/#{team_rid}"
  end
end
