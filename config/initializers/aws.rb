# frozen_string_literal: true
require 'aws-sdk-s3'

if ENV['AWS_ROLE_ARN'].present? && ENV['AWS_WEB_IDENTITY_TOKEN_FILE'].present?
  Aws.config.update \
    credentials: Aws::AssumeRoleWebIdentityCredentials.new(
      client: Aws::STS::Client.new,
      role_arn: ENV.fetch('AWS_ROLE_ARN', nil),
      web_identity_token_file: ENV.fetch('AWS_WEB_IDENTITY_TOKEN_FILE', nil),
      role_session_name: "kudochest-#{Rails.env}-session"
    )
end
