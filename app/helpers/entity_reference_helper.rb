# frozen_string_literal: true
module EntityReferenceHelper
  def helpers
    ActionController::Base.helpers
  end

  def channel_link(rid)
    "<#{CHAN_PREFIX}#{rid}>"
  end

  def channel_webref(name)
    helpers.tag.span("#{CHAN_PREFIX}#{name}", class: 'chat-ref')
  end

  def subteam_webref(name)
    helpers.tag.span(name, class: 'chat-ref')
  end

  def mention_pattern(platform)
    <<~TEXT.gsub(/\s+/, '')
      (?:
        <
          (
            (?:
              #{Regexp.escape(PROFILE_PREFIX[platform])}
              |
              #{Regexp.escape(CHAN_PREFIX)}
              |
              #{Regexp.escape(SUBTEAM_PREFIX[platform])}
            )
            #{RID_CHARS[platform]}+
          )
          (?:#{LEGACY_SLACK_SUFFIX_PATTERN})?
        >
        |
        #{GROUP_KEYWORD_PATTERN[platform]}
      )
    TEXT
  end

  # TODO: leave emoji str in here and bail out in mention parser if emoji disabled?
  # that's how we handle jabs
  def tip_pattern(emoji_str, emoji: true)
    emoji ? plus_or_emojis_maybe_int(emoji_str) : plus_maybe_int
  end

  def plus_or_emojis_maybe_int(emoji_str)
    "#{quantity_prefix}(?:#{text_inlines}|((?:(?::#{emoji_str}:\s*)+)))#{quantity_suffix}"
  end

  def text_inlines
    "(#{plus_plus}|#{minus_minus})"
  end

  def plus_maybe_int
    quantity_prefix + text_inlines + quantity_suffix
  end

  def quantity_prefix
    '(\d*\.?\d*)\s?'
  end

  def quantity_suffix
    '\s?(\d*\.?\d*)'
  end

  def mention_regex(platform, emoji_str, emoji: true)
    Regexp.new("#{mention_pattern(platform)}#{maybe_spaces}#{tip_pattern(emoji_str, emoji:)}")
  end

  def maybe_spaces
    '\s{0,2}'
  end

  # "++" or "+="
  def point_inline
    patterns = POINT_INLINES.map { |str| Regexp.escape(str) }.join('|')
    "(?:#{patterns})"
  end

  # "--" or "-="
  def jab_inline
    patterns = JAB_INLINES.map { |str| Regexp.escape(str) }.join('|')
    "(?:#{patterns})"
  end
end
