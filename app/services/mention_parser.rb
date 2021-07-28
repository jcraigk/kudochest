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
    TipMentionService.call(
      profile: profile,
      mentions: mentions,
      note: note,
      source: 'plusplus',
      event_ts: event_ts,
      channel_rid: channel_rid,
      channel_name: channel_name
    )
  end

  def mentions
    stacked_mentions.reject { |mention| mention.quantity.zero? }
  end

  # `@user++ @user++ @user++`
  #   => @user gets 1 Tip of quantity 3
  # `@user :fire: @user :high_brightness: @user :fire:`
  #   => @user gets 2 Tips (1) :fire: x2 (2) :high_brightness: x1
  def stacked_mentions
    raw_mentions.group_by(&:rid).map do |rid, mentions_by_rid|
      mentions_by_rid.group_by(&:topic_id).map do |topic_id, mentions|
        OpenStruct.new(
          rid: rid,
          topic_id: topic_id,
          quantity: mentions.sum(&:quantity)
        )
      end
    end.flatten
  end

  def raw_mentions
    matches.map do |match|
      OpenStruct.new(
        rid: match.profile_rid,
        topic_id: tip_topic_id(match),
        quantity: tip_quantity(match)
      )
    end
  end

  # `<@UFOO> :fire: :high_brightness:` => :fire: topic is used
  def tip_topic_id(match)
    return unless team.enable_topics?

    if match.emoji_string.present?
      first_emoji = match.emoji_string.split(':').reject(&:blank?).first
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
    float = (match.prefix_digits.presence || match.suffix_digits.presence).to_f
    return (float.zero? ? 1.0 : float) if match.emoji_string.blank?
    return 0 unless team.enable_emoji?
    num = num_inline_emoji(match.emoji_string)
    # If single emoji, use prefix/suffix digit if present
    return float if num == 1 && float.positive?
    # Otherwise, multiply by emoji quantity
    num * team.emoji_quantity
  end

  # `:high_brightness: :fire:` => first emoji is used for topic, but gets 2 quantity
  # TODO: Split this out into 2 Tips
  def num_inline_emoji(emoji_string)
    emoji_string.split(':').reject(&:blank?).count do |emoji|
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
