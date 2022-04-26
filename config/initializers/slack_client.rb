# frozen_string_literal: true
Slack::Events.configure do |config|
  config.signature_expires_in = Rails.env.development? ? 5.seconds : 5.minutes
  config.signing_secret = ENV.fetch('SLACK_SIGNING_SECRET', nil)
end
