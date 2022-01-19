# frozen_string_literal: true
require 'redis'

RedisClient = # rubocop:disable Naming/ConstantName
  if ENV['REDIS_URL'].present?
    Redis.new
  else
    Redis.new \
      host: ENV['IN_DOCKER'] ? 'redis' : 'localhost',
      port: 6379
  end
