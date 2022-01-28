# frozen_string_literal: true
class Hooks::Slack::EventsController < Hooks::Slack::BaseController
  EVENT_KEYS = %w[
    app_home_opened
    app_uninstalled
    channel_archive
    channel_created
    channel_deleted
    channel_rename
    channel_unarchive
    message
    reaction_added
    reaction_removed
    subteam_created
    subteam_members_changed
    subteam_updated
    team_join
    team_rename
    user_change
  ].freeze

  def receiver
    return unless relevant_action?
    super
  end

  private

  def fast_ack
    return unless mentions_found?
    super
  end

  def relevant_action?
    event_type != 'message' || bot_dm? || relevant_text?
  end

  def bot_dm?
    event[:channel_type] == 'im' &&
      params.dig(:authorizations, 0, :user_id) == config[:app_profile_rid]
  end

  def data # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    {
      action:,
      channel_rid: event.dig(:item, :channel) || event[:channel],
      event_ts: event[:event_ts],
      event:,
      is_bot_dm: bot_dm?,
      message_ts: event.dig(:item, :ts),
      origin: bot_dm? ? 'bot-dm' : 'channel',
      profile_rid: event[:user], # This can be a JSON object (`user_change`, for example)
      config: team_config,
      team_rid: params[:team_id],
      text:,
      thread_ts: event[:thread_ts],
      event_params: params.to_unsafe_h
    }
  end

  def action
    @action ||=
      if event_type.start_with?('channel_')
        'channel_sync'
      elsif event_type.start_with?('subteam_')
        'subteam_sync'
      elsif event_type.in?(EVENT_KEYS)
        event_type
      end
  end

  def event_type
    @event_type ||= event[:type]
  end

  def event
    @event ||= params[:event].to_unsafe_h
  end

  def text
    @text ||= event[:text]
  end
end
