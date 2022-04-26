# frozen_string_literal: true
require 'rmagick'

class ResponseImageService < Base::Service
  option :type
  option :config
  option :fragments,    default: proc { {} }
  option :tips,         default: proc { [] }
  option :profile_data, default: proc { [] }
  option :title,        default: proc { '' }

  def call
    if config[:platform].to_sym == :slack
      store_image
      assign_image_acl
      image_url
    else
      image_file
    end
  end

  private

  def store_image
    Aws::S3::Client.new.put_object \
      bucket: ENV.fetch('RESPONSE_IMAGE_AWS_BUCKET', nil),
      key:,
      body: File.read(image_file)
    File.delete(image_file)
  end

  def assign_image_acl
    Aws::S3::Client.new.put_object_acl \
      bucket: ENV.fetch('RESPONSE_IMAGE_AWS_BUCKET', nil),
      key:,
      acl: 'public-read'
  end

  def image_url
    @image_url ||= "https://#{ENV.fetch('RESPONSE_IMAGE_HOST', 'localhost')}/#{key}"
  end

  def image_file
    @image_file ||= "Image::#{type.titleize}Service".constantize.call(**params)
  end

  def params
    {
      config:,
      fragments:,
      tips:,
      profile_data:,
      title:
    }.compact
  end

  def key
    @key ||= "#{SecureRandom.uuid}.gif"
  end
end
