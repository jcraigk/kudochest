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

  def mention_regex(config)
    Regexp.new("#{mention_pattern(config)}#{maybe_spaces}#{inline_pattern(config)}")
  end

  def mention_pattern(config)
    platform = config.platform
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

  def inline_pattern(config)
    "#{quantity_prefix}(?:(#{inlines})|((?:#{emojis(config)}\s*)+))#{quantity_suffix}"
  end

  def inlines
    "#{inline_point}|#{inline_jab}"
  end

  def emojis(config)
    str = valid_emojis(config).join('|').presence || 'no-emoji'
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

  def inline_point
    patterns = POINT_INLINES.map { |str| Regexp.escape(str) }.join('|')
    "(?:#{patterns})"
  end

  def inline_jab
    patterns = JAB_INLINES.map { |str| Regexp.escape(str) }.join('|')
    "(?:#{patterns})"
  end

  def valid_emojis(config)
    return [] unless config.enable_emoji
    emojis = [config.tip_emoji]
    emojis << config.jab_emoji if config.enable_jabs
    emojis << config.topics.map(&:emoji) if config.enable_topics
    emojis
  end
end
