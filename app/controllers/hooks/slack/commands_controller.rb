# frozen_string_literal: true
class Hooks::Slack::CommandsController < Hooks::Slack::BaseController
  private

  def fast_ack
    return unless mentions_found?
    super
  end

  def data # rubocop:disable Metrics/MethodLength
    {
      action: 'message',
      channel_name: params[:channel_name],
      channel_rid: params[:channel_id],
      event_ts: Time.current.to_f.to_s,
      origin: 'command',
      profile_rid: params[:user_id],
      config: team_config,
      team_rid: params[:team_id],
      text:,
      trigger_id: params[:trigger_id]
    }
  end

  def text
    @text ||= params[:text]&.strip
  end
end
