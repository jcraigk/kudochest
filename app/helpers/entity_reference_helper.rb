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
    helpers.tag.span("#{PROF_PREFIX}#{name}", class: 'chat-ref')
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
        #{EVERYONE_PATTERN[platform]}
      )
    TEXT
  end

  def tip_pattern(emoji_str, emoji: true)
    emoji ? plus_or_emojis_maybe_int(emoji_str) : plus_maybe_int
  end

  def plus_or_emojis_maybe_int(emoji_str)
    quantity_prefix + # rubocop:disable Style/StringConcatenation
      '(?:' +
      plus_plus +
      '|((?::' +
      emoji_str +
      ':\s*)+))' +
      quantity_suffix
  end

  def plus_maybe_int
    quantity_prefix + plus_plus + quantity_suffix
  end

  def quantity_prefix
    '(\d*\.?\d*)\s?'
  end

  def quantity_suffix
    '\s?(\d*\.?\d*)'
  end

  def mention_regex(platform, emoji_str, emoji: true)
    Regexp.new("#{mention_pattern(platform)}#{maybe_spaces}#{tip_pattern(emoji_str, emoji: emoji)}")
  end

  def maybe_spaces
    '\s{0,2}'
  end

  def plus_plus
    '(?:\+\+|\+\=)'
  end
end
