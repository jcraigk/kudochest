# frozen_string_literal: true

# Scan a message from the chat client to find triggrs that could result in Tip creation.
# Because this is called on every message sent from chat, it should be efficient.

class MessageScanner < Base::Service
  param :text
  param :config

  attr_reader :platform

  def call
    @platform = config[:platform].to_sym
    matches_on_text
  end

  private

  def scan_results
    @scan_results ||= sanitized_text.scan(regex).map do |match|
      regex.names.map(&:to_sym).zip(match).to_h
    end || []
  end

  def matches_on_text # rubocop:disable Metrics/MethodLength
    scan_results.each_with_index.map do |match, idx|
      {
        rid: rid(match),
        prefix_quantity: prefix_quantity(match),
        inline_text: inline_text(match),
        inline_emoji: sanitized_emoji(match),
        suffix_quantity: suffix_quantity(match),
        topic_keyword: topic_keyword(match),
        note: note(idx)
      }.compact
    end
  end

  def topic_keyword(match)
    match[:topic_keywords].presence
  end

  def inline_text(match)
    match[:inlines].presence
  end

  def prefix_quantity(match)
    quantity_or_nil(match[:prefix_quantity])
  end

  def suffix_quantity(match)
    quantity_or_nil(match[:suffix_quantity])
  end

  def rid(match)
    match[:entity_rid] || match[:group_keyword]
  end

  def quantity_or_nil(str)
    return if str.blank?
    str += '0' if str.end_with?('.')
    BigDecimal(str)
  end

  def sanitized_emoji(match)
    match[:emojis]&.gsub(/[^a-z_\-:]/, '')
  end

  def note(idx)
    NoteSanitizer.call(platform:, team_rid: config[:rid], text: raw_note(idx))
  end

  # Note is all text between matches, defaulting to tail
  def raw_note(idx)
    tail = text.split(scan_results[idx][:match])[1]
    return tail if (next_match = scan_results[idx + 1]&.dig(:match)).nil?
    intermediate_note(tail, next_match) || tail_note
  end

  def intermediate_note(tail, next_match)
    tail&.split(next_match)&.first&.strip.presence
  end

  def tail_note
    @tail_note ||= text.split(scan_results[-1][:match])[1]&.strip
  end

  def topic_keywords
    "(?<topic_keywords>#{config[:topics]&.pluck(:keyword)&.join('|')})?"
  end

  def sanitized_text
    text&.strip&.tr("\u00A0", ' ') || '' # `\u00A0` is unicode space (from Slack)
  end

  def regex
    Regexp.new("(?<match>#{mention}#{spaces}#{triggers}#{spaces}#{topic_keywords})")
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
        #{group_keyword_pattern[platform]}
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
    '(?<prefix_quantity>\d+\.?\d*)?\s?'
  end

  def quantity_suffix
    '\s?(?<suffix_quantity>\d+\.?\d*)?'
  end

  def spaces
    '\s{0,20}'
  end

  def group_keyword_pattern
    {
      slack: '<!(?<group_keyword>everyone|channel|here)>',
      discord: '@(?<group_keyword>everyone|channel|here)'
    }
  end
end
