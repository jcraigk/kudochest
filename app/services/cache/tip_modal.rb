# frozen_string_literal: true

# We need to cache the channel in which the modal was triggered
# because that is not provided when the modal is submitted.

class Cache::TipModal
  PREFIX = 'modal'

  def self.set(key, channel_rid, channel_name)
    RedisClient.set(
      "#{PREFIX}/#{key}",
      [channel_rid, channel_name].join(':'),
      ex: App.modal_cache_ttl
    )
  end

  def self.get(key)
    key = "#{PREFIX}/#{key}"
    val = RedisClient.get(key)&.split(':') || []
    OpenStruct.new(
      channel_rid: val.first,
      channel_name: val.second
    )
  end
end
