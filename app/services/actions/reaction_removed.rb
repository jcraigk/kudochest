# frozen_string_literal: true
class Actions::ReactionRemoved < Actions::Base
  def call
    return unless relevant_emoji? && tip.present?
    tip.destroy
    respond
  end

  private

  def respond
    OpenStruct.new(mode: :silent)
  end

  # TODO: Does this work in Discord?
  def tip
    @tip ||=
      Tip.undoable
         .where(event_ts: event_ts, source: source)
         .find_by(from_profile: profile)
  end

  def event_ts
    @event_ts ||= "#{params[:message_ts]}-#{emoji}-#{profile.id}"
  end

  def source
    @source ||= (emoji == team.ditto_emoji ? 'ditto' : 'reaction')
  end

  def relevant_emoji?
    team.enable_emoji? && (slack_emoji? || discord_emoji?)
  end

  def slack_emoji?
    team.platform.slack? && emoji.in?(relevant_emojis)
  end

  def discord_emoji?
    team.platform.discord? && emoji.in?(relevant_emojis)
  end

  def relevant_emojis
    @relevant_emojis ||= [team.tip_emoji, team.ditto_emoji]
  end

  def emoji
    @emoji ||=
      case team.platform
      when 'slack' then params[:event][:reaction]
      when 'discord' then params[:emoji]
      end
  end
end
