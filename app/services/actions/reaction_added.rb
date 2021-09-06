# frozen_string_literal: true
class Actions::ReactionAdded < Actions::ReactionBase
  def call
    return unless process_emoji?
    process_reaction_and_respond
  end

  private

  def process_reaction_and_respond
    TipMentionService.call(
      profile: profile,
      mentions: mentions,
      source: source,
      event_ts: event_ts,
      channel_rid: params[:channel_rid],
      channel_name: channel_name
    )
  end

  def mentions
    case source
    when 'ditto' then ditto_mentions
    when 'reaction' then author_mention
    end
  end

  def ditto_mentions
    ditto_tips.map do |tip|
      OpenStruct.new(
        rid: "#{PROF_PREFIX}#{tip.to_profile.rid}",
        topic_id: tip.topic_id,
        quantity: tip.quantity
      )
    end
  end

  def ditto_tips
    @ditto_tips ||=
      Tip.includes(:to_profile)
         .where(event_ts: message_ts)
         .or(Tip.where(response_ts: message_ts))
  end

  def author_mention
    [
      OpenStruct.new(
        rid: "#{PROF_PREFIX}#{author_profile_rid}",
        topic_id: topic_id,
        quantity: team.emoji_quantity
      )
    ]
  end

  def author_profile_rid
    params.dig(:event, :item_user) || params[:to_profile_rid]
  end

  def channel_name
    params[:channel_name].presence || channel&.name
  end

  # Must fetch since channel_name is not provided by Slack Event callback
  def channel
    @channel ||= Channel.find_with_team(params[:team_rid], params[:channel_rid])
  end
end
