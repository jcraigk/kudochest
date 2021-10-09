# frozen_string_literal: true
module ProfileHelper
  LVL_BACKGROUNDS = %w[
    wood woodleaves stone stoneleaves bronze silver gold sapphire ruby columnleaves
  ].freeze

  def level_progress_bar_footer(profile)
    tag.span(class: 'progress-footer') do
      break 'Maximum level' if profile.max_level?
      <<~TEXT.chomp
        Earn #{points_format(profile.points_required_for_next_level, label: true)} to level up
      TEXT
    end
  end

  def percent_of_current_level(profile)
    return 100 if profile.max_level?
    return 0 unless (points_toward_next = points_toward_next_level(profile)).positive?
    ((points_toward_next / profile.points_required_for_next_level.to_f) * 100).floor
  end

  def points_toward_next_level(profile)
    profile.points - points_required_for_current_level(profile)
  end

  def points_required_for_current_level(profile)
    LevelToPointsService.call(team: profile.team, level: profile.level)
  end

  def level_progress_bar(profile)
    tag.progress(
      class: 'progress profile-level-progress',
      value: percent_of_current_level(profile),
      max: 100,
      title: profile.next_level_points_sentence
    )
  end

  def profile_web_link(profile, team = nil)
    team ||= profile.team
    tag.span(class: 'profile-link') do
      css = "avatar platform-#{team.platform}"
      h = image_tag(profile.avatar_url, size: 20, alt: 'Avatar image', class: css)
      h += link_to(profile.display_name, profile_path(profile.slug))
      h + " (#{profile.real_name})" if profile.display_name != profile.real_name
      h
    end
  end

  def direction_with_icon(tip, profile)
    dir, word = tip.from_profile == profile ? %w[right Given] : %w[left Earned]
    tag.span(class: "points-direction-#{dir}") do
      tag.i(class: "fas fa-arrow-#{dir}") + ' ' + word # rubocop:disable Style/StringConcatenation
    end
  end

  def level_badge(profile)
    tag.div(
      class: "level-badge #{level_background_class(profile)}"
    ) do
      level_as_pixel_digits(profile.level)
    end
  end

  def level_as_pixel_digits(lvl)
    lvl.to_s.chars.map do |digit|
      image_pack_tag "media/images/levels/digits/#{digit}.png", class: 'digit', alt: "Level #{lvl}"
    end.join.html_safe # rubocop:disable Rails/OutputSafety
  end

  def level_background_class(profile)
    return LVL_BACKGROUNDS.last if profile.max_level?
    num_levels = profile.team.max_level - 1
    num_badges = LVL_BACKGROUNDS.size - 1
    mult = num_badges / num_levels.to_f
    idx = (profile.level * mult).ceil - 1
    LVL_BACKGROUNDS[idx]
  end

  def avatar_image(profile, size: 150)
    image_tag(
      profile.avatar_url,
      alt: 'Profile avatar image',
      size: size,
      class: "platform-#{profile.team.platform}"
    )
  end
end
