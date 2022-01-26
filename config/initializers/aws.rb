# frozen_string_literal: true
require 'aws-sdk-s3'

if ENV['AWS_ROLE_ARN'].present? && ENV['AWS_WEB_IDENTITY_TOKEN_FILE'].present?
  Aws.config.update \
    credentials: Aws::AssumeRoleWebIdentityCredentials.new(
      region: ENV['AWS_REGION'],
      client: Aws::STS::Client.new,
      role_arn: ENV['AWS_ROLE_ARN'],
      web_identity_token_file: ENV['AWS_WEB_IDENTITY_TOKEN_FILE'],
      role_session_name: "kudochest-#{Rails.env}-session"
    )
end
