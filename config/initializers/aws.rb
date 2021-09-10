# frozen_string_literal: true
require 'aws-sdk-s3'

Aws.config.update(
  credentials: Aws::AssumeRoleCredentials.new(
    client: Aws::STS::Client.new(
      region: ENV['AWS_REGION'],
      credentials: {
        session_token: File.read(ENV.fetch('AWS_WEB_IDENTITY_TOKEN_FILE', 'tmp'))
      }
    ),
    role_arn: ENV['AWS_ROLE_ARN'],
    role_session_name: 'kudochest-session'
  )
)
