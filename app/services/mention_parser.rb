# frozen_string_literal: true
class MentionParser < Base::Service
  option :team_rid
  option :profile_rid
  option :event_ts
  option :channel_rid
  option :channel_name
  option :matches

  def call
    process_tip_mentions
  end

  private

  def process_tip_mentions
    TipMentionService.call \
      profile:,
      mentions:,
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
  # `@user++ great @user++ work!`
  #   => @user gets 1 Tip of quantity 2 with note "great work!"
  def stacked_mentions
    processed_mentions.group_by(&:rid).map do |rid, mentions_by_rid|
      mentions_by_rid.group_by(&:topic_id).map do |topic_id, mentions|
        note = mentions.pluck(:note).join(' ').presence
        Mention.new(rid:, topic_id:, quantity: mentions.sum(&:quantity), note:)
      end
    end.flatten
  end

  def processed_mentions
    matches.map do |match|
      Mention.new \
        rid: match[:rid],
        topic_id: tip_topic_id(match),
        quantity: tip_quantity(match),
        note: match[:note]
    end
  end

  def tip_topic_id(match)
    return unless team.enable_topics?
    topic_id_from_emoji(match) || topic_id_from_match(match)
  end

  # TODO: Pass in team config and use that to get topic ids (save a db query)
  # `<@UFOO> :fire: :star: :up:` => `fire` topic is used (first in sequence)
  def topic_id_from_emoji(match)
    return if match[:inline_emoji].blank?
    first_emoji = match[:inline_emoji].split(':').compact_blank.first
    team.topics.active.find { |topic| first_emoji == topic.emoji }&.id
  end

  def topic_id_from_match(match)
    return if (keyword = match[:topic_keyword]).blank?
    team.topics.active.find { |topic| keyword == topic.keyword }&.id
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
    given = (match[:prefix_quantity].presence || match[:suffix_quantity].presence).to_f
    return emoji_match_quantity(match, given) if match[:inline_emoji].present?
    negative = match[:inline_text].in?(JAB_INLINES)
    given, default = negative ? [0 - given, -1.0] : [given, 1.0]
    given.zero? ? default : given
  end

  def emoji_match_quantity(match, quantity)
    emojis = match[:inline_emoji].split(':').compact_blank
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
