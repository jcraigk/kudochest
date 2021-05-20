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

  def call
    @action = action&.to_sym
    @team_config = OpenStruct.new(team_config)
    @response_text = {}

    if response_mode == :silent && tips.any?
      respond_in_convo(log_channel_rid) if copy_to_log_channel?
      return
    end

    attach_and_broadcast if mode != :fast_ack
    post_response
  end

  private

  def log_channel_rid
    @log_channel_rid ||= team_config.log_channel_rid
  end

  def response_mode
    @response_mode ||= team_config.response_mode&.to_sym
  end

  def attach_and_broadcast
    # TODO: should response tips be attached to log channel if :silent?
    attach_response_tips unless response_mode == :silent
    respond_in_convo(log_channel_rid) if copy_to_log_channel?
    broadcast_via_websocket
  end

  def copy_to_log_channel?
    tips.any? && log_channel_rid.present? && log_channel_rid != channel_rid
  end

  def broadcast_via_websocket
    return if tips.none?
    ResponseChannel.broadcast_to(sender.team, response.web)
  end

  def sender
    @sender ||= tips.first.from_profile
  end

  def attach_response_tips
    return unless tips.any?
    Tip.where(id: tips.map(&:id)).update_all( # rubocop:disable Rails/SkipsModelValidations
      response_channel_rid: post_response_channel_rid,
      response_ts: post_response_ts
    )
  end

  def chat_response_text(to_channel_rid = nil)
    fast_ack_text || response_text(to_channel_rid)
  end

  def first_tip
    @first_tip ||= tips.first
  end

  def response_text(to_channel_rid)
    @response_text[to_channel_rid] ||= compose_response(to_channel_rid)
  end

  def compose_response(to_channel_rid)
    return image if image.present?
    return text unless any_chat_fragments?
    append_channel if append_channel?(to_channel_rid)
    fragment_composition
  end

  def append_channel
    text = response.chat_fragments[1].delete_suffix('!')
    response.chat_fragments[1] = "#{text} in <#{CHAN_PREFIX}#{first_tip.from_channel_rid}>"
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

  def append_channel?(to_channel_rid)
    team_config.show_channel &&
      first_tip&.from_channel_name &&
      to_channel_rid != first_tip&.from_channel_rid
  end
end
