# frozen_string_literal: true
require 'aws-sdk-s3'

credentials =
  if ENV['AWS_ROLE_ARN'].present? && ENV['AWS_WEB_IDENTITY_TOKEN_FILE'].present?
    Aws::AssumeRoleWebIdentityCredentials.new(
      client: Aws::STS::Client.new,
      role_arn: ENV['AWS_ROLE_ARN'],
      web_identity_token_file: ENV['AWS_WEB_IDENTITY_TOKEN_FILE'],
      role_session_name: "kudochest-#{Rails.env}-session"
    )
  else
    Aws::Credentials.new(
      ENV['RESPONSE_IMAGE_AWS_ACCESS_KEY_ID'].presence || ENV['AWS_ACCESS_KEY_ID'],
      ENV['RESPONSE_IMAGE_AWS_SECRET_ACCESS_KEY'].presence || ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

Aws.config.update(
  region: ENV['RESPONSE_IMAGE_AWS_REGION'] || ENV['AWS_REGION'].presence,
  credentials: credentials
)
