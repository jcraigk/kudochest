# frozen_string_literal: true
class Hooks::Slack::ActionsController < Hooks::Slack::BaseController
  CALLBACK_IDS = %w[reply_tip submit_tip_modal submit_prefs_modal].freeze

  def receiver
    return unless relevant_action?
    super
  end

  private

  def relevant_action?
    callback_id.in?(CALLBACK_IDS)
  end

  def data # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    payload.merge(
      action: callback_id,
      channel_name: payload.dig(:channel, :name) || modal_channel.name,
      channel_rid: payload.dig(:channel, :id) || modal_channel.rid,
      event_ts: Time.current.to_f.to_s,
      message_profile_rid: payload.dig(:message, :user),
      message_ts: payload.dig(:message, :ts),
      profile_rid:,
      team_config: team_config.to_h,
      team_rid:
    )
  end

  def profile_rid
    @profile_rid ||= payload[:user][:id]
  end

  def team_rid
    @team_rid ||= payload[:team][:id]
  end

  def modal_channel
    @modal_channel ||= Cache::TipModal.get("#{team_rid}/#{profile_rid}")
  end

  def callback_id
    @callback_id ||= payload[:callback_id] || payload.dig(:view, :callback_id)
  end

  def payload
    @payload ||= JSON.parse(params[:payload], symbolize_names: true)
  end
end
