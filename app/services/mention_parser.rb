# frozen_string_literal: true
class MentionParser < Base::Service
  option :team_rid
  option :profile_rid
  option :event_ts
  option :channel_rid
  option :channel_name
  option :matches
  option :note

  def call
    process_tip_mentions
  end

  private

  def process_tip_mentions
    TipMentionService.call \
      profile:,
      mentions:,
      note:,
      source: 'trigger',
      event_ts:,
      channel_rid:,
      channel_name:
  end

  def mentions
    stacked_mentions.reject { |mention| mention.quantity.zero? }
  end

  # `@user++ @user++ @user++`
  #   => @user gets 1 Tip of quantity 3
  # `@user-- @user-- @user--`
  #   => @user gets 1 Tip of quantity -3
  # `@user :fire: @user :high_brightness: @user :fire:`
  #   => @user gets 2 Tips (1) :fire: x2 (2) :high_brightness: x1
  def stacked_mentions
    raw_mentions.group_by(&:rid).map do |rid, mentions_by_rid|
      mentions_by_rid.group_by(&:topic_id).map do |topic_id, mentions|
        Mention.new(rid:, topic_id:, quantity: mentions.sum(&:quantity))
      end
    end.flatten
  end

  def raw_mentions
    matches.map do |m|
      Mention.new(rid: m.profile_rid, topic_id: tip_topic_id(m), quantity: tip_quantity(m))
    end
  end

  # `<@UFOO> :fire: :high_brightness:` => :fire: topic is used
  def tip_topic_id(match)
    return unless team.enable_topics?

    if match.emoji_string.present?
      first_emoji = match.emoji_string.split(':').compact_blank.first
      team.topics.active.find { |topic| first_emoji == topic.emoji }&.id
    else
      topic_id_from_note
    end
  end

  # `LeaderShip great job!` => "leadership" topic is used, note becomes "great job!"
  def topic_id_from_note
    return if note.blank?

    words = note.split(/\s+/)
    topic_id = team.topics.active.find { |topic| words.first.downcase == topic.keyword }&.id
    @note = words.drop(1).join(' ') if topic_id
    topic_id
  end

  # `<@UFOO> 3++2` => 3 is used
  def tip_quantity(match) # rubocop:disable Metrics/AbcSize
    negative = match.operation == 'subtract'
    explicit_quant = (match.prefix_digits.presence || match.suffix_digits.presence).to_f
    if negative
      return 0 unless team.enable_jabs?
      explicit_quant = 0 - explicit_quant
    end

    # If no emoji found
    if match.emoji_string.blank?
      default_quant = negative ? -1.0 : 1.0
      explicit_quant.zero? ? default_quant : explicit_quant
    # Else if emoji found
    else
      # TODO: Check if there was a mixture of points/jabs and reject if so?
      return 0 unless team.enable_emoji?
      num_emojis = num_inline_emoji(match.emoji_string)
      # If single emoji, use explicit prefix/suffix digits if provided
      if num_emojis == 1 && !explicit_quant.zero?
        explicit_quant
      # Otherwise, multiply by emoji quantity
      else
        quantity = num_emojis * team.emoji_quantity
        negative ? 0 - quantity : quantity
      end
    end
  end

  # `:high_brightness: :fire:` => first emoji is used for topic, but gets 2 quantity
  # TODO: Split this out into 2 Tips
  def num_inline_emoji(emoji_string)
    emoji_string.split(':').compact_blank.count do |emoji|
      emoji == team.tip_emoji || emoji.in?(team.topics.active.map(&:emoji))
    end
  end

  def team
    @team ||= profile.team
  end

  def profile
    @profile ||= Profile.find_with_team(team_rid, profile_rid)
  end
end
