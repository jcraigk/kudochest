# frozen_string_literal: true
class Image::LeaderboardService < Base::ImageService
  option :profile_data
  option :title

  WIDTH = 400

  HEADER_HEIGHT = 30
  ROW_HEIGHT = 26

  STRIPE_COLORS = {
    day: '#e7e7e7',
    night: '#363636'
  }.freeze

  private

  def composite_image
    height = HEADER_HEIGHT + (BODY_PAD * 2) + (profile_data.size * ROW_HEIGHT)
    comp = solid_color_background(WIDTH, height)

    comp = add_header_bg(comp)
    comp = resize_and_round(comp, "#{WIDTH}x#{height}", 5)

    comp = add_team_avatar(comp)

    comp = add_header_text(comp)
    comp = add_body(comp)

    add_animated_gif(comp)
  end

  def add_animated_gif(comp)
    comp.delay = GIF_SPEED
    random_gif(32).map do |frame|
      comp.composite(frame, WIDTH - 40, 6, Magick::OverCompositeOp)
    end
  end

  def add_team_avatar(comp)
    comp.composite \
      avatar_image(team_config.avatar_url),
      Magick::NorthWestGravity,
      HEADER_PAD,
      HEADER_PAD,
      Magick::OverCompositeOp
  end

  def add_header_text(comp)
    draw = Magick::Draw.new
    draw.font = FONT_FILE
    draw.pointsize = 26
    draw.gravity = Magick::NorthWestGravity

    color = body_colors.first
    draw.annotate(comp, 0, 0, 50, 6, title.delete('*')) do
      self.fill = color
    end

    comp
  end

  def add_body(comp) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    draw = Magick::Draw.new
    draw.font = FONT_FILE
    draw.gravity = Magick::NorthWestGravity

    color1 = body_colors.first
    color2 = body_colors.second

    y = 48
    profile_data.each_with_index do |data, idx| # rubocop:disable Metrics/BlockLength
      draw.pointsize = 17
      x = BODY_PAD + 5

      # Stripes
      if idx.odd?
        color = STRIPE_COLORS[theme]
        stripe = Magick::Image.new(WIDTH, ROW_HEIGHT) { self.background_color = color }
        stripe = resize_and_round(stripe, "#{WIDTH - 10}x#{ROW_HEIGHT}", 5)
        comp = comp.composite(stripe, Magick::NorthWestGravity, 5, y - 2, Magick::OverCompositeOp)
      end

      # Rank
      if data.rank <= 3
        trophy = Magick::ImageList.new("#{BASE_PATH}/trophies/#{data.rank}.png")
        comp = comp.composite \
          trophy,
          Magick::NorthWestGravity,
          x,
          y + 3,
          Magick::OverCompositeOp
      else
        draw.text_align(Magick::RightAlign)
        value = "#{data.rank}."
        draw.annotate(comp, 0, 0, x, y, value) do
          self.fill = color1
        end
      end
      x += 35

      # Avatar
      comp = comp.composite \
        avatar_image(data.avatar_url, 16),
        Magick::NorthWestGravity,
        x,
        y + 2,
        Magick::OverCompositeOp
      x += 25

      # Name
      draw.text_align(Magick::LeftAlign)
      draw.annotate(comp, 0, 0, x, y, data.display_name) do
        self.fill = color2
      end
      x += 165

      # Points
      draw.annotate(comp, 0, 0, x, y, points_format(data.points)) do
        self.fill = color1
      end
      x += 45

      # Percent share
      # value = number_to_percentage(data.percent_share, significant: true, precision: 2)
      # draw.annotate(comp, 0, 0, x, y, value) do
      #   self.fill = color1
      # end
      # x += 28

      # Timestamp
      draw.pointsize = 13
      value = time_ago_in_words \
        Time.use_zone(team_config.time_zone) { Time.at(data.last_timestamp).utc }
      value = (value == 'less than a minute' ? 'just now' : "#{value} ago")
      draw.annotate(comp, 0, 0, x + 15, y + 4, value) do
        self.fill = color1
      end

      y += ROW_HEIGHT
    end

    comp
  end
end
