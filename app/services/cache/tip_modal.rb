# We need to cache the channel in which the modal was triggered
# because that is not provided when the modal is submitted.

class Cache::TipModal
  PREFIX = 'modal'.freeze

  def self.set(key, channel_rid, channel_name)
    REDIS.setex \
      "#{PREFIX}/#{key}",
      App.modal_cache_ttl,
      [channel_rid, channel_name].join(':')
  end

  def self.get(key)
    key = "#{PREFIX}/#{key}"
    val = REDIS.get(key)&.split(':') || []
    ChannelData.new(val.first, val.second)
  end
end
