# frozen_string_literal: true
class Image::TipService < Base::ImageService
  option :fragments
  option :tips

  WIDTH = 500
  MAIN_HEIGHT = 100

  CHEER_FONT_SIZE = 16
  CHEER_ROW_HEIGHT = 20
  CHEER_PAD = 35

  private

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def composite_image
    cheer_pad = any_cheers? ? CHEER_PAD : BODY_PAD
    height = MAIN_HEIGHT + cheer_pad + (CHEER_ROW_HEIGHT * cheer_fragments.size) + BODY_PAD
    comp = solid_color_background(WIDTH, height)

    comp = add_header_bg(comp)
    comp = resize_and_round(comp, "#{WIDTH}x#{height}", 5)

    comp = add_recipient_avatars(comp)
    comp = add_sender_avatar(comp)
    comp = add_quantity(comp)

    comp = add_from_or_channel_text(comp)
    comp = add_body_text(comp)
    comp = add_cheers(comp)

    add_animated_gif(comp)
  end

  def add_cheer_text(comp)
    draw = Magick::Draw.new
    draw.font = FONT_FILE
    draw.pointsize = CHEER_FONT_SIZE
    draw.gravity = Magick::NorthWestGravity

    colors = body_colors.reverse
    y = MAIN_HEIGHT + CHEER_PAD
    cheer_fragments.each do |text|
      x = BODY_PAD
      text.split(IMG_DELIM).reject(&:blank?).each_with_index do |chunk, idx|
        draw.annotate(comp, 0, 0, x, y, chunk) do
          self.fill = colors[idx % 2]
        end
        x += draw.get_type_metrics(chunk).width.to_i
      end
      y += CHEER_ROW_HEIGHT
    end

    comp
  end

  def add_from_or_channel_text(comp)
    # Channel
    if team_config.show_channel
      channel_name = "#{CHAN_PREFIX}#{first_tip.from_channel_name}"

      draw = Magick::Draw.new
      draw.font = FONT_FILE
      draw.pointsize = 16
      draw.gravity = Magick::NorthEastGravity

      badge_width = draw.get_type_metrics(channel_name).width + 6
      x = 46
      y = 21
      badge_height = 20
      bg_color = BG_COLOR[theme]

      badge = Magick::Image.new(badge_width, badge_height) { self.background_color = bg_color }
      badge = resize_and_round(badge, "#{badge_width}x#{badge_height}", 5)
      comp = comp.composite(badge, Magick::NorthEastGravity, x, y, Magick::OverCompositeOp)

      color = BODY_COLORS[theme].second
      draw.annotate(comp, 0, 0, x + 2, y - 1, channel_name) do
        self.fill = color
      end
    else
      # "from"
      draw = Magick::Draw.new
      draw.font = FONT_FILE
      draw.pointsize = 16
      draw.gravity = Magick::NorthEastGravity
      color = BODY_COLORS[theme].first
      draw.annotate(comp, 0, 0, 45, 24, 'from') do
        self.fill = color
      end
    end

    comp
  end

  def add_body_text(comp)
    body_width = WIDTH - 100
    body_height = 57
    text_width = body_width + 1
    text_height = body_height + 1

    # puts "max: #{body_width} x #{body_height}"

    fontsize = MAX_FONT_SIZE

    draw = Magick::Draw.new
    draw.font = FONT_FILE
    draw.gravity = Magick::NorthWestGravity

    while (text_width > body_width || text_height > body_height) && fontsize > MIN_FONT_SIZE
      fontsize -= 1
      draw.pointsize = fontsize
      metrics = draw.get_multiline_type_metrics(raw_body_text)
      text_width = metrics.width
      text_height = metrics.height
      # puts "at fontsize #{fontsize}, w: #{text_width}, h: #{text_height}"
    end
    # puts "Final: #{fontsize}"

    colors = body_colors

    body_height = 76
    header_height = 44
    y = header_height + ((body_height - text_height) / 2.0).floor
    main_fragments.each_with_index do |fragment, frag_idx|
      next if fragment.blank?

      x = BODY_PAD
      fragment.split(IMG_DELIM).each_with_index do |chunk, idx|
        next if chunk.blank?

        draw = Magick::Draw.new
        if frag_idx == 2
          chunk = truncate(chunk, length: 70)
          draw.font = FONT_FILE_ITALIC
        else
          draw.font = FONT_FILE
        end
        draw.pointsize = fontsize
        draw.gravity = Magick::NorthWestGravity
        draw.annotate(comp, 0, 0, x, y, chunk) do
          self.fill = colors[idx % 2]
        end

        x += draw.get_type_metrics(chunk).width.to_i
      end
      y += fontsize + (fontsize * 0.3).floor
    end

    # Cover extra long text with same color background
    comp.composite(
      solid_color_background(300, 300),
      Magick::NorthWestGravity,
      body_width + 10,
      46,
      Magick::OverCompositeOp
    )
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def raw_body_text
    @raw_body_text ||=
      main_fragments.compact
                    .map { |frag| frag.gsub(IMG_DELIM, '').gsub(/\s+/, ' ').gsub(' ,', ',') }
                    .join("\n")
  end

  def add_cheers(comp)
    return comp unless any_cheers?
    comp = add_cheer_hr(comp)
    add_cheer_text(comp)
  end

  def add_cheer_hr(comp)
    draw = Magick::Draw.new
    draw.stroke('gray')
    draw.stroke_width(1)
    draw.line(BODY_PAD, MAIN_HEIGHT + 25, WIDTH - BODY_PAD, MAIN_HEIGHT + 25)
    draw.draw(comp)
    comp
  end

  def any_cheers?
    team_config.enable_cheers && cheer_fragments.any?
  end

  def cheer_fragments
    @cheer_fragments ||= fragments.slice(:levelup, :streak).values.reject(&:blank?)
  end

  def main_fragments
    @main_fragments ||= fragments.slice(:lead, :main, :note).values
  end

  def timestamp
    @timestamp ||= Time.use_zone(team_config.time_zone) { first_tip.created_at }
  end

  def profile_avatar(profile)
    avatar_image(small_profile_avatar_url(profile))
  end

  def add_animated_gif(comp) # rubocop:disable Metrics/AbcSize
    gif_sequence = random_gif(48)
    force_loop = gif_sequence.first.filename.split('/')[-2].in?(GIF_NO_REST)
    comp.delay = GIF_SPEED

    Magick::ImageList.new.tap do |ilist|
      gif_sequence.each_with_index do |frame, idx|
        # frame = frame.resize(48, 48, Magick::PointFilter) # Scale up but retain pixelart
        new_frame = comp.composite(frame, WIDTH - 65, 58, Magick::OverCompositeOp)
        new_frame.delay = GIF_REST if idx + 1 == gif_sequence.size && !force_loop
        ilist << new_frame
      end
    end
  end

  def add_sender_avatar(comp)
    sender_avatar = profile_avatar(first_tip.from_profile)
    comp.composite(
      sender_avatar,
      Magick::NorthEastGravity,
      HEADER_PAD,
      HEADER_PAD,
      Magick::OverCompositeOp
    )
  end

  def add_quantity(comp)
    first_tip.quantity.in?((1..5).to_a) ? add_graphical_quantity(comp) : add_text_quantity(comp)
  end

  def add_graphical_quantity(comp)
    img = Magick::ImageList.new("#{BASE_PATH}/quantities/#{first_tip.quantity.to_i}.png").first
    x = avatar_stack_right + 44
    comp.composite(img, Magick::NorthWestGravity, x, 6, Magick::OverCompositeOp)
  end

  def add_text_quantity(comp) # rubocop:disable Metrics/AbcSize
    draw = Magick::Draw.new
    draw.font = FONT_FILE
    draw.pointsize = 34
    draw.gravity = Magick::NorthWestGravity
    x = avatar_stack_right + 44
    y = 3
    text = "+#{points_format(first_tip.quantity)}"
    draw.annotate(comp, 0, 0, x, y, text) { self.fill = '#3b1b20' }
    draw.annotate(comp, 0, 0, x - 2, y - 2, text) { self.fill = '#f0cf28' }

    comp
  end

  def num_avatars
    @num_avatars ||= [recipient_profiles.size, MAX_PROFILES].min
  end

  def avatar_stack_right
    @avatar_stack_right ||= HEADER_PAD + (PROFILE_EDGE * (num_avatars - 1))
  end

  def add_recipient_avatars(comp)
    x = avatar_stack_right

    # Add stack of up to MAX_PROFILES
    recipient_profiles.shuffle.take(num_avatars).each do |profile|
      recipient_avatar = profile_avatar(profile)
      comp = comp.composite(recipient_avatar, x, HEADER_PAD, Magick::OverCompositeOp)
      x -= PROFILE_EDGE
    end

    comp
  end

  def first_tip
    @first_tip ||= tips.first
  end

  def recipient_profiles
    tips.map(&:to_profile).uniq
  end
end
