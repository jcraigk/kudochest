Sidekiq.default_job_options = { backtrace: true }

redis_url = "redis://#{ENV.fetch('IN_DOCKER', false) ? 'redis' : 'localhost'}:6379"
redis_config = { url: ENV.fetch('REDIS_URL', redis_url) }

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.redis = redis_config

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

# https://github.com/mperham/sidekiq/wiki/Monitoring
class AdminConstraint
  def matches?(request)
    return true if Rails.env.development?
    User.find_by(id: request.session[:user_id])&.admin? || false
  end
end
