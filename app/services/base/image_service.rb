# frozen_string_literal: true
class Base::ImageService < Base::Service
  include PointsHelper

  option :config

  RADII = {
    slack: 5,
    discord: 30
  }.freeze

  BASE_PATH = 'lib/response_images'
  DEBUG_FILE = "#{BASE_PATH}/debug.gif".freeze

  TMP_PATH = "#{STORAGE_PATH}/response_images/tmp".freeze
  CACHE_PATH = "#{STORAGE_PATH}/response_images/cache".freeze
  DEFAULT_AVATAR = "#{BASE_PATH}/avatars/default-avatar-36.png".freeze

  BG_COLOR = {
    day: '#f5f5f5',
    night: '#1b1d21'
  }.freeze
  BODY_COLORS = {
    day: %w[black #1c9bd1],
    night: %w[white #789cd6]
  }.freeze
  FOOTER_COLORS = {
    day: %w[gray #1c9bd1],
    night: %w[gray #789cd6]
  }.freeze

  GIF_SPEED = 45
  GIF_REST = 500
  GIF_NO_REST = %w[comet confetti cherries fire star].freeze

  FONT_FILE = "#{BASE_PATH}/fonts/BarlowSemiCondensed-Regular.ttf".freeze
  FONT_FILE_ITALIC = "#{BASE_PATH}/fonts/BarlowSemiCondensed-Italic.ttf".freeze
  MIN_FONT_SIZE = 15
  MAX_FONT_SIZE = 40

  MAX_PROFILES = 10
  PROFILE_SIZE = 36
  PROFILE_EDGE = 10

  HEADER_PAD = 5
  BODY_PAD = 10

  def call
    # return composite_image.write(DEBUG_FILE)

    composite_image.write(tmpfile)
    tmpfile
  end

  private

  def random_gif(size = 48)
    folder = "#{BASE_PATH}/gifs/#{size}/#{GIFS[size.to_s].sample}"
    files = (1..Dir["#{folder}/*"].size).to_a.map { |num| "#{folder}/#{num}.png" }
    Magick::ImageList.new(*files)
  end

  def tmpfile
    @tmpfile ||= "#{TMP_PATH}/#{SecureRandom.uuid}.gif"
  end

  def theme
    @theme ||= config[:response_theme].delete_prefix('gif_').to_sym
  end

  def body_colors
    BODY_COLORS[theme]
  end

  def footer_colors
    FOOTER_COLORS[theme]
  end

  def solid_color_background(width, height)
    color = BG_COLOR[theme]
    Magick::Image.new(width, height) { |m| m.background_color = color }
  end

  def add_header_bg(comp)
    header_img = "#{BASE_PATH}/headers/#{theme}.png"
    header = Magick::ImageList.new(header_img)
    comp.composite(header, Magick::NorthGravity, 0, 0, Magick::OverCompositeOp)
  end

  def resize_and_round(source_image, geometry_str, radius)
    source_image.change_geometry(geometry_str) do |width, height, img|
      thumb = img.resize(width, height)

      # Create a transparency mask for border radius
      mask = Magick::Image.new(width, height) { |m| m.background_color = 'transparent' }
      Magick::Draw.new.stroke('none').stroke_width(0).fill('white')
                  .roundrectangle(0, 0, width, height, radius, radius).draw(mask)

      thumb.composite(mask, 0, 0, Magick::CopyAlphaCompositeOp)
    end
  end

  def small_profile_avatar_url(profile)
    small_avatar_url(profile.team.platform, profile.avatar_url)
  end

  def small_avatar_url(platform, url)
    case platform.to_sym
    when :slack then url.gsub(/_\d+\.png\z/, '_48.png')
    when :discord then url.gsub(/\?size=\d+\z/, '?size=64')
    end
  end

  def avatar_image(url, size = PROFILE_SIZE)
    file = file_from_url(url)
    avatar_image = file.present? ? Magick::ImageList.new(file) : blank_avatar
    resize_and_round \
      avatar_image,
      "#{size}x#{size}",
      RADII[config[:platform].to_sym]
  end

  def blank_avatar
    resize_and_round \
      Magick::ImageList.new(DEFAULT_AVATAR).first,
      "#{PROFILE_SIZE}x#{PROFILE_SIZE}",
      RADII[config[:platform].to_sym]
  end

  def file_from_url(url)
    filename = "#{CACHE_PATH}/#{Digest::MD5.hexdigest(url)}.png"
    return filename if File.exist?(filename)

    begin
      response = HTTP.follow.get(url)
    rescue HTTP::Redirector::TooManyRedirectsError
      return false
    end
    return unless response.code == 200

    File.binwrite(filename, response.body)
    filename
  end
end
