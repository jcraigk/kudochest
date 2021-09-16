# frozen_string_literal: true

return if ENV['SENTRY_DSN'].blank?

Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.traces_sample_rate = 0.2
end
