# frozen_string_literal: true
Sidekiq.default_worker_options = { backtrace: true }

redis_url = "redis://#{ENV['IN_DOCKER'] ? 'redis' : 'localhost'}:6379"
redis_config = { url: ENV['REDIS_URL'].presence || redis_url }

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

# https://github.com/mperham/sidekiq/wiki/Monitoring
class AdminConstraint
  def matches?(request)
    return true if Rails.env.development?
    User.find_by(id: request.session[:user_id])&.admin? || false
  end
end
