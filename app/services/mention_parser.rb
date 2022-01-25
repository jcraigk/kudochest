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

  def tip_quantity(match) # rubocop:disable Metrics/AbcSize
    # `<@UFOO> 3++2` => 3 is used
    given_quant = (match.prefix_digits.presence || match.suffix_digits.presence).to_f
    if match.inline_emoji.present?
      emojis = match.inline_emoji.split(':').compact_blank
      # Do not allow different emojis - only multiple instances of same emoji
      return 0 unless team.enable_emoji? && emojis.uniq.size == 1
      emoji_quant =
        if emojis.size == 1 && !given_quant.zero?
          # If single emoji with prefix/suffix, use those digits
          given_quant
        else
          # Otherwise, multiply by number of emoji instances
          emojis.size * team.emoji_quantity
        end
      emojis.first == team.jab_emoji ? 0 - emoji_quant : emoji_quant
    else
      negative = match.inline_text.in?(JAB_INLINES)
      explicit, default = negative ? [0 - given_quant, -1.0] : [given_quant, 1.0]
      given_quant.zero? ? default : explicit
    end
  end

  def team
    @team ||= profile.team
  end

  def profile
    @profile ||= Profile.find_with_team(team_rid, profile_rid)
  end
end
