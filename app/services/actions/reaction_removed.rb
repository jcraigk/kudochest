# frozen_string_literal: true
class Actions::ReactionRemoved < Actions::Base
  def call
    return unless tip_emoji? && tip.present?
    tip.destroy
    respond
  end

  private

  def respond
    OpenStruct.new(mode: :silent)
  end

  def tip
    @tip ||= Tip.undoable.where(event_ts: params[:message_ts]).find_by(from_profile: profile)
  end

  def tip_emoji?
    team.enable_emoji? && (slack_emoji? || discord_emoji?)
  end

  def slack_emoji?
    team.platform.slack? && params[:event][:reaction] == team.tip_emoji
  end

  def discord_emoji?
    team.platform.discord? && params[:emoji] == App.discord_emoji
  end
end
