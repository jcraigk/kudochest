# frozen_string_literal: true

# We need to cache the channel in which the modal was triggered
# because that is not provided when the modal is submitted.

class Cache::TipModal
  PREFIX = 'modal'

  def self.set(key, channel_rid, channel_name)
    REDIS.set \
      "#{PREFIX}/#{key}",
      [channel_rid, channel_name].join(':'),
      ex: App.modal_cache_ttl.seconds.from_now
  end

  def self.get(key)
    key = "#{PREFIX}/#{key}"
    val = REDIS.get(key)&.split(':') || []
    ChannelData.new(val.first, val.second)
  end
end
