# frozen_string_literal: true
class Base::PostService < Base::Service
  option :mode
  option :team_config
  option :action,           default: proc {}
  option :channel_rid,      default: proc {}
  option :event_ts,         default: proc {}
  option :is_bot_dm,        default: proc { false }
  option :message_ts,       default: proc {}
  option :profile_rid,      default: proc {}
  option :response,         default: proc {}
  option :text,             default: proc {}
  option :image,            default: proc {}
  option :tips,             default: proc { [] }

  attr_reader :log_channel_rid, :response_mode

  def call
    @action = action&.to_sym
    @team_config = OpenStruct.new(team_config)
    @log_channel_rid = team_config.log_channel_rid
    @response_mode = team_config.response_mode&.to_sym

    handle_responses
  end

  private

  def handle_responses
    return post_log_message if response_mode == :silent
    return post_response if mode == :fast_ack
    post_to_all_channels
  end

  def post_to_all_channels
    post_response
    attach_tips_to_response
    broadcast_via_websocket
    post_log_message
  end

  def post_log_message
    return unless post_in_log_channel?
    respond_in_convo(log_channel_rid)
  end

  def post_in_log_channel?
    tips.any? && log_channel_rid.present? && log_channel_rid != channel_rid
  end

  def broadcast_via_websocket
    return if tips.none?
    ResponseChannel.broadcast_to(sender.team, response.web)
  end

  def sender
    @sender ||= tips.first.from_profile
  end

  def attach_tips_to_response
    return if tips.none? || (response_mode == :silent && log_channel_rid.blank?)
    Tip.where(id: tips.map(&:id)).update_all( # rubocop:disable Rails/SkipsModelValidations
      response_channel_rid: log_channel_rid.presence || post_response_channel_rid,
      response_ts: post_response_ts
    )
  end

  def chat_response_text
    fast_ack_text || compose_response
  end

  def first_tip
    @first_tip ||= tips.first
  end

  def compose_response
    return image if image.present?
    return text unless any_chat_fragments?
    fragment_composition
  end

  def fragment_composition
    [main_text, cheer_text].compact.join("\n")
  end

  def join_fragments(fragments)
    return if fragments.blank?
    fragments.join(' ')
  end

  def cheer_text
    return unless team_config.enable_cheers
    join_fragments(chat_fragments[3..]&.reject(&:blank?))
  end

  def main_text
    join_fragments(chat_fragments.first(3)&.reject(&:blank?))
  end

  def chat_fragments
    @chat_fragments ||= response&.chat_fragments
  end

  def any_chat_fragments?
    chat_fragments&.any?(&:present?)
  end
end
