# frozen_string_literal: true
require 'aws-sdk-s3'

Aws.config.update(
  region: ENV['RESPONSE_IMAGE_AWS_REGION'],
  credentials: Aws::Credentials.new(
    ENV['RESPONSE_IMAGE_AWS_ACCESS_KEY_ID'],
    ENV['RESPONSE_IMAGE_AWS_SECRET_ACCESS_KEY']
  )
)
