# frozen_string_literal: true
class Hooks::Slack::BaseController < Hooks::BaseController
  include ActionView::Helpers::NumberHelper

  before_action :verify_challenge_param
  before_action :ignore_irrelevant_messages!
  before_action :verify_slack_request!
  before_action :verify_team_active!

  def receiver
    enqueue_slack_event_worker
    head :ok
  end

  protected

  def enqueue_slack_event_worker
    payload = data.merge(fast_ack_data).merge(matches:).to_json
    EventWorker.perform_async(payload)
  end

  def fast_ackable?
    team_config[:enable_fast_ack] &&
      !team_config[:response_mode].in?(%w[silent direct]) &&
      !private_command? &&
      !prefs_submission?
  end

  def prefs_submission?
    json_payload.dig(:view, :callback_id) == 'submit_prefs_modal'
  end

  def private_command?
    return false if mentions_found?
    PRIVATE_KEYWORDS.find { |cmd| text.split(/\s+/).take(2).include?(cmd) }.present?
  end

  def mentions_found?
    @mentions_found ||= matches.any?
  end

  def matches
    @matches ||= MessageScanner.call(text, team_config)
  end

  def relevant_text?
    @relevant_text ||=
      text&.start_with?("<#{PROF_PREFIX}#{team_config[:app_profile_rid]}>") || mentions_found?
  end

  def fast_ack_data
    {
      platform: 'slack',
      replace_channel_rid: fast_ack&.dig(:channel),
      replace_ts: fast_ack&.dig(:ts)
    }
  end

  def fast_ack
    return unless fast_ackable?
    @fast_ack ||= Slack::PostService.call(**data.merge(mode: :fast_ack))
  end

  private

  def ignore_irrelevant_messages!
    return if
      params.dig(:message, :subtype) != 'bot_message' &&
      params.dig(:event, :bot_id).blank? &&
      params.dig(:event, :subtype).blank?
    head :ok
  end

  def verify_slack_request!
    Slack::Events::Request.new(request).verify!
  rescue Slack::Events::Request::MissingSigningSecret,
         Slack::Events::Request::TimestampExpired,
         Slack::Events::Request::InvalidSignature
    head :forbidden
  end

  def verify_team_active!
    return if team_config[:active]
    head :ok
  end

  def text
    @text ||= params.dig(:event, :text) || ''
  end

  # Naming this `config` messes with Rails logger :shrug:
  def team_config
    @team_config ||= Cache::TeamConfig.call(team_rid)
  end

  def team_rid
    params[:team_id] || params.dig(:event, :team) || json_payload.dig(:team, :id)
  end

  def channel_rid
    params[:channel_id] || params.dig(:event, :channel) || json_payload.dig(:channel, :id)
  end

  def json_payload
    return {} if params[:payload].blank?
    @json_payload ||= JSON.parse(params[:payload], symbolize_names: true)
  end

  def verify_challenge_param
    return if params[:challenge].blank?
    render plain: params[:challenge]
  end
end
