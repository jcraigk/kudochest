# frozen_string_literal: true

# We need to cache the channel in which the modal was triggered
# because that is not provided when the modal is submitted.

class Cache::TipModal
  PREFIX = 'modal'

  def self.set(key, channel_rid, channel_name)
    Rails.cache.set \
      "#{PREFIX}/#{key}",
      [channel_rid, channel_name].join(':'),
      expires_in: App.modal_cache_ttl.seconds.from_now
  end

  def self.get(key)
    key = "#{PREFIX}/#{key}"
    val = Rails.cache.get(key)&.split(':') || []
    ChannelData.new(val.first, val.second)
  end
end
