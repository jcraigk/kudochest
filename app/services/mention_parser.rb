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
      source: 'inline',
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
    parsed_mentions.group_by(&:rid).map do |rid, mentions_by_rid|
      mentions_by_rid.group_by(&:topic_id).map do |topic_id, mentions|
        Mention.new(rid:, topic_id:, quantity: mentions.sum(&:quantity))
      end
    end.flatten
  end

  def parsed_mentions
    matches.map do |m|
      Mention.new(rid: m.profile_rid, topic_id: tip_topic_id(m), quantity: tip_quantity(m))
    end
  end

  def tip_topic_id(match)
    return unless team.enable_topics?
    topic_id_from_emoji(match) || topic_id_from_note
  end

  # `<@UFOO> :fire: :star: :up:` => `fire` topic is used (first in sequence)
  def topic_id_from_emoji(match)
    return if match.inline_emoji.blank?
    first_emoji = match.inline_emoji.split(':').compact_blank.first
    team.topics.active.find { |topic| first_emoji == topic.emoji }&.id
  end

  # `LeaderShip great job!` => "leadership" topic is used, note becomes "great job!"
  def topic_id_from_note
    return if note.blank?

    words = note.split(/\s+/)
    topic_id = team.topics.active.find { |topic| words.first.downcase == topic.keyword }&.id
    @note = words.drop(1).join(' ') if topic_id
    topic_id
  end

  # Generate a quantity given a mention match
  #
  # Examples:
  # "@user ++" => 1
  # "@user 3++2" => 3
  # "@user --4" => -4
  # "@user :point::point:" => 2 * team.emoji_quantity
  # "@user :point::jab:" => 0 (rejected for non-unique emoji)
  # "@user :jab::jab::jab:" => -3
  def tip_quantity(match)
    given = (match.prefix_digits.presence || match.suffix_digits.presence).to_f
    if match.inline_emoji.present?
      emoji_match_quantity(match, given)
    else
      negative = match.inline_text.in?(JAB_INLINES)
      given, default = negative ? [0 - given, -1.0] : [given, 1.0]
      given.zero? ? default : given
    end
  end

  def emoji_match_quantity(match, quantity)
    emojis = match.inline_emoji.split(':').compact_blank
    # Do not allow different emojis - only multiple instances of same emoji
    return 0 unless team.enable_emoji? && emojis.uniq.size == 1
    emoji_quant = emojis_quantity(emojis, quantity)
    emojis.first == team.jab_emoji ? 0 - emoji_quant : emoji_quant
  end

  def emojis_quantity(emojis, quantity)
    # If single emoji with prefix/suffix, use those digits
    return quantity if emojis.size == 1 && !quantity.zero?
    # Otherwise, multiply by number of emoji instances
    emojis.size * team.emoji_quantity
  end

  def team
    @team ||= profile.team
  end

  def profile
    @profile ||= Profile.find_with_team(team_rid, profile_rid)
  end
end
