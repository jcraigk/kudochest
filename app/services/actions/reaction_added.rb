# frozen_string_literal: true
class Actions::ReactionAdded < Actions::Base
  def call
    return unless team.enable_emoji? && relevant_emoji?
    process_reaction_and_respond
  end

  private

  def process_reaction_and_respond
    TipMentionService.call(
      profile: profile,
      mentions: mentions,
      source: 'reaction',
      event_ts: params[:message_ts],
      channel_rid: params[:channel_rid],
      channel_name: channel_name
    )
  end

  def topic_id
    return if emoji == team.tip_emoji
    team.config.topics.find { |topic| topic.emoji == emoji }&.id
  end

  def mentions
    [
      OpenStruct.new(
        rid: "#{PROF_PREFIX}#{to_profile_rid}",
        topic_id: topic_id,
        quantity: team.emoji_quantity
      )
    ]
  end

  def to_profile_rid
    params.dig(:event, :item_user) || params[:to_profile_rid]
  end

  def emoji
    params.dig(:event, :reaction) || params[:emoji]
  end

  def relevant_emoji?
    standard_emoji? || topic_id.present?
  end

  def standard_emoji?
    slack_standard_emoji? || discord_standard_emoji?
  end

  def slack_standard_emoji?
    team.platform.slack? && emoji == team.tip_emoji
  end

  def discord_standard_emoji?
    team.platform.discord? && emoji == App.discord_emoji
  end

  def topics
    @topics ||= team.topics.active
  end

  def channel_name
    params[:channel_name].presence || channel&.name
  end

  # Must lookup since channel_name not provided by Slack Event callback payload
  def channel
    @channel ||= Channel.find_with_team(params[:team_rid], params[:channel_rid])
  end
end
