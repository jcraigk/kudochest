# frozen_string_literal: true
require 'rmagick'

class ResponseImageService < Base::Service
  option :type
  option :team_config
  option :fragments,    default: proc { OpenStruct.new }
  option :tips,         default: proc { [] }
  option :profile_data, default: proc { [] }
  option :title,        default: proc { '' }

  def call
    if team_config.platform.to_sym == :slack
      store_image
      image_url
    else
      image_file
    end
  end

  private

  def store_image
    Aws::S3::Client.new.put_object(
      bucket: ENV['RESPONSE_IMAGE_AWS_BUCKET'].presence || ENV['AWS_S3_BUCKET'],
      key: key,
      body: File.read(image_file)
    )
    File.delete(image_file)
  end

  def image_url
    @image_url ||= "https://#{ENV['RESPONSE_IMAGE_HOST']}/#{key}"
  end

  def image_file
    @image_file ||= "Image::#{type.titleize}Service".constantize.call(params)
  end

  def params
    {
      team_config: team_config,
      fragments: fragments,
      tips: tips,
      profile_data: profile_data,
      title: title
    }.compact
  end

  def key
    @key ||= "#{SecureRandom.uuid}.gif"
  end
end
