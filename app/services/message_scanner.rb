# frozen_string_literal: true
class MessageScanner < Base::Service
  param :text
  param :config

  attr_reader :platform

  def call
    @platform = config[:platform].to_sym
    return [] if text.blank?
    matches_on_text
  end

  private

  def matches_on_text # rubocop:disable Metrics/MethodLength
    sanitized_text.scan(regex).map do |match|
      {
        profile_rid: match[0] || match[1], # entity_rid || group_keyword
        prefix_digits: match[2],
        inline_text: match[3],
        inline_emoji: sanitized_emoji(match[4]),
        suffix_digits: match[5],
        topic_keyword: match[6]&.strip,
        note: sanitized_note(match[7])
      }
    end || []
  end

  def sanitized_emoji(str)
    str&.gsub(/[^a-z_:]/, '')
  end

  def sanitized_note(str)
    NoteSanitizer.call(platform:, team_rid: config[:rid], text: str)
  end

  def note
    '(?<note>[^<>]*)'
  end

  def topic_keywords
    str = config[:topics].pluck(:keyword).join('|')
    "(?<topic_keywords>#{str})?"
  end

  def sanitized_text
    text.strip.tr("\u00A0", ' ') # Unicode space (from Slack)
  end

  def regex
    Regexp.new("#{mention}#{space}#{triggers}#{space}#{topic_keywords}#{note}")
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
    '(?<prefix_digits>\d*\.?\d*)\s?'
  end

  def quantity_suffix
    '\s?(?<suffix_digits>\d*\.?\d*)'
  end

  def space
    '\s{0,2}'
  end
end
