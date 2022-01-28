# frozen_string_literal: true
class Actions::ReactionBase < Actions::Base
  protected

  def message_ts
    @message_ts ||= params[:message_ts]
  end

  def event_ts
    @event_ts ||= "#{message_ts}-#{source}#{topic_suffix}-#{profile.id}"
  end

  def source
    @source ||=
      case emoji
      when team.point_emoji then 'point_reaction'
      when team.jab_emoji then 'jab_reaction'
      when team.ditto_emoji then 'ditto_reaction'
      end
  end

  def topic_suffix
    return if topic.blank?
    "-topic#{topic.id}"
  end

  def topic
    @topic ||= team&.config&.dig(:topics)&.find { |topic| topic.emoji == emoji }
  end

  def topic_id
    @topic_id ||= topic&.id
  end

  def process_emoji?
    team&.enable_emoji? && relevant_emoji?
  end

  def relevant_emoji?
    emoji.in?([team.point_emoji, team.jab_emoji, team.ditto_emoji]) || topic_emoji?
  end

  def topic_emoji?
    team.enable_topics? && topic_id.present?
  end

  def emoji
    @emoji ||=
      case team.platform
      when 'slack' then params[:event][:reaction]
      when 'discord' then params[:emoji]
      end
  end
end
