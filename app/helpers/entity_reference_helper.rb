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

  # TODO: Move this to a service, it doesn't belong in this helper
  def mention_regex(config)
    Regexp.new("#{mention_pattern(config)}#{maybe_spaces}#{trigger_pattern(config)}")
  end

  def mention_pattern(config)
    platform = config[:platform]
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

  def trigger_pattern(config)
    inline_capture = "(#{inlines(config)})"
    emoji_capture = "((?:#{emojis(config)}\s*)+)"
    "#{quantity_prefix}(?:#{inline_capture}|#{emoji_capture})#{quantity_suffix}"
  end

  def inlines(config)
    patterns = POINT_INLINES.map { |str| Regexp.escape(str) }
    patterns << JAB_INLINES.map { |str| Regexp.escape(str) } if config[:enable_jabs]
    patterns.join('|')
  end

  def emojis(config)
    str = emoji_patterns(config).join('|').presence || 'no-emoji'
    ":(?:#{str}):"
  end

  def quantity_prefix
    '(\d*\.?\d*)\s?'
  end

  def quantity_suffix
    '\s?(\d*\.?\d*)'
  end

  def maybe_spaces
    '\s{0,2}'
  end

  def emoji_patterns(config)
    return [] unless config[:enable_emoji]
    emojis = [config[:tip_emoji]]
    emojis << config[:jab_emoji] if config[:enable_jabs]
    emojis << config[:topics].map(&:emoji) if config[:enable_topics]
    emojis
  end
end
