# frozen_string_literal: true

# Scan a message from the chat client to find triggrs that could result in Tip creation.
# Because this is called on every message sent from chat, it should be efficient.

class MessageScanner < Base::Service
  param :text
  param :config

  attr_reader :platform

  def call
    @platform = config[:platform].to_sym
    matches_on_text || []
  end

  private

  def matches_on_text # rubocop:disable Metrics/MethodLength
    sanitized_text.presence&.scan(regex)&.map do |match|
      {
        rid: rid(match),
        prefix_quantity: prefix_quantity(match),
        inline_text: inline_text(match),
        inline_emoji: sanitized_emoji(match),
        suffix_quantity: suffix_quantity(match),
        topic_keyword: topic_keyword(match),
        note: note(match)
      }.compact
    end
  end

  def topic_keyword(match)
    match[6].presence
  end

  def inline_text(match)
    match[3].presence
  end

  def prefix_quantity(match)
    quantity_or_nil(match[2])
  end

  def suffix_quantity(match)
    quantity_or_nil(match[5])
  end

  def rid(match)
    match[0] || match[1] # entity_rid || group_keyword
  end

  def quantity_or_nil(str)
    return if str.blank?
    BigDecimal(str)
  end

  def sanitized_emoji(match)
    match[4]&.gsub(/[^a-z_:]/, '')
  end

  def note(match)
    text = match[7]&.strip
    NoteSanitizer.call(platform:, team_rid: config[:rid], text:)
  end

  def maybe_note
    '(?<note>[^<>]*)'
  end

  def topic_keywords
    str = config[:topics].pluck(:keyword).join('|')
    "(?<topic_keywords>#{str})?"
  end

  def sanitized_text
    text&.strip&.tr("\u00A0", ' ') # Unicode space (from Slack)
  end

  def regex
    Regexp.new("#{mention}#{space}#{triggers}#{space}#{topic_keywords}#{maybe_note}")
  end

  def mention
    <<~TEXT.gsub(/\s+/, '')
      (?:
        <
          (?<entity_rid>
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

  def triggers
    "#{quantity_prefix}(?:#{inlines}|#{emojis})#{quantity_suffix}"
  end

  def inlines
    patterns = POINT_INLINES.map { |str| Regexp.escape(str) }
    patterns << JAB_INLINES.map { |str| Regexp.escape(str) } if config[:enable_jabs]
    "(?<inlines>#{patterns.join('|')})"
  end

  def emojis
    patterns = emoji_patterns.map { |str| ":#{str}:" }
    patterns.map! { |str| "<#{str}\\d+>" } if platform == :discord
    str = patterns.join('|').presence || 'no-emoji'
    "(?<emojis>(?:(?:#{str})\\s*)+)"
  end

  def emoji_patterns
    return [] unless config[:enable_emoji]
    emojis = [config[:point_emoji]]
    emojis << config[:jab_emoji] if config[:enable_jabs]
    emojis += config[:topics].pluck(:emoji) if config[:enable_topics]
    emojis
  end

  def quantity_prefix
    '(?<prefix_quantity>\d*\.?\d*)\s?'
  end

  def quantity_suffix
    '\s?(?<suffix_quantity>\d*\.?\d*)'
  end

  def space
    '\s{0,2}'
  end
end
