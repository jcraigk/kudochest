# frozen_string_literal: true
class Base::PostService < Base::Service
  option :mode
  option :config
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
    @log_channel_rid = config[:log_channel_rid]
    @response_mode = config[:response_mode]&.to_sym

    handle_responses
  end

  private

  def handle_responses
    return post_log_message if response_mode == :silent
    return post_response if mode == :fast_ack
    return post_hint if mode == :hint
    post_to_all_channels
  end

  def post_to_all_channels
    post_response
    attach_tips_to_response
    broadcast_via_websocket
    post_log_message
  end

  def post_hint
    respond_in_convo(config[:hint_channel_rid])
  end

  def post_log_message
    return unless post_in_log_channel?
    respond_in_convo(log_channel_rid, nil)
  end

  def post_in_log_channel?
    tips.present? && log_channel_rid.present? && log_channel_rid != channel_rid
  end

  def broadcast_via_websocket
    return if tips.blank?
    ResponseChannel.broadcast_to(sender.team, response.web)
  end

  def sender
    @sender ||=
      tips&.first&.from_profile ||
      Profile.find_with_team(team_rid, profile_rid)
  end

  def attach_tips_to_response
    return if tips.blank? ||
              post_response_ts.blank? ||
              (response_mode == :silent && log_channel_rid.blank?)

    Tip.where(id: tips.map(&:id)).update_all( # rubocop:disable Rails/SkipsModelValidations
      response_channel_rid: log_channel_rid.presence || post_response_channel_rid,
      response_ts: post_response_ts
    )
  end

  def chat_response_text(is_inline: true)
    fast_ack_text || compose_response(is_inline)
  end

  def first_tip
    @first_tip ||= tips&.first
  end

  def compose_response(is_inline)
    return image if image.present?
    return text if mode == :hint || no_chat_fragments?
    fragment_composition(is_inline)
  end

  def fragment_composition(is_inline)
    [primary_text(is_inline), cheer_text].compact_blank.join("\n")
  end

  def cheer_text
    return unless config[:enable_cheers]
    [chat_fragments[:leveling], chat_fragments[:streak]].compact_blank.join("\n")
  end

  def primary_text(is_inline) # rubocop:disable Metrics/AbcSize
    parts = chat_fragments.slice(:lead, :main)
    note = chat_fragments[:note]
    channel = chat_fragments[:channel]
    parts[:main] += " #{channel}" if channel.present? && !is_inline && config[:show_channel]
    parts[:main] += ". #{note}" if note.present? && (is_inline || config[:show_note])
    parts.values.compact_blank.join("\n")
  end

  def chat_fragments
    @chat_fragments ||= response&.chat_fragments
  end

  def no_chat_fragments?
    chat_fragments&.compact.blank?
  end
end
