# frozen_string_literal: true
require 'rmagick'

class ResponseImageService < Base::Service
  option :type
  option :team_config
  option :fragments,    default: proc { {} }
  option :tips,         default: proc { [] }
  option :profile_data, default: proc { [] }
  option :title,        default: proc { '' }

  def call
    if team_config.platform.to_sym == :slack
      store_image
      assign_image_acl
      image_url
    else
      image_file
    end
  end

  private

  def store_image
    Aws::S3::Client.new.put_object(
      bucket: ENV['RESPONSE_IMAGE_AWS_BUCKET'],
      key:,
      body: File.read(image_file)
    )
    File.delete(image_file)
  end

  def assign_image_acl
    Aws::S3::Client.new.put_object_acl(
      bucket: ENV['RESPONSE_IMAGE_AWS_BUCKET'],
      key:,
      acl: 'public-read'
    )
  end

  def image_url
    @image_url ||= "https://#{ENV['RESPONSE_IMAGE_HOST']}/#{key}"
  end

  def image_file
    @image_file ||= "Image::#{type.titleize}Service".constantize.call(**params)
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
