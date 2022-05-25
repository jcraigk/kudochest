# frozen_string_literal: true
require 'redis'

RedisClient = # rubocop:disable Naming/ConstantName
  if ENV.fetch('REDIS_URL', nil).present?
    Redis.new
  else
    Redis.new \
      host: ENV.fetch('IN_DOCKER', false) ? 'redis' : 'localhost',
      port: 6379
  end
