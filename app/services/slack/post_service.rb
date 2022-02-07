# frozen_string_literal: true
class Slack::PostService < Base::PostService
  option :team_rid
  option :replace_channel_rid,  default: proc {}
  option :replace_ts,           default: proc {}
  option :thread_ts,            default: proc {}
  option :trigger_id,           default: proc {}

  private

  def post_response
    @post_response ||= respond_in_slack
  end

  def respond_in_slack
    return handle_replacement if replace_ts
    case mode
    when :prefs_modal then render_prefs_modal
    when :tip_modal then render_tip_modal
    when :error, :private then respond_ephemeral(profile_rid)
    when :direct then respond_dm(profile_rid)
    when :public, :fast_ack then respond_by_mode
    end
  end

  def handle_replacement
    mode == :silent ? delete_message : replace_message
  end

  def respond_by_mode
    case response_action
    when :convo then respond_in_convo(channel_rid)
    when :reply then is_bot_dm ? respond_dm(profile_rid) : reply_to_message
    when :direct then dm_tipped_profiles
    when :silent then respond_ephemeral(profile_rid)
    end
  end

  def dm_tipped_profiles
    recipients.select(&:allow_dm?).each do |profile|
      respond_dm(profile.rid)
    end
    respond_dm(sender.rid)
  end

  def fallback_to_dm_response
    recipients.each { |recipient| respond_dm(recipient.rid) }
    respond_dm(profile_rid)
  end

  def reply_to_message
    return respond_in_convo if action == :submit_tip_modal
    thread = parent_ts || message_ts || event_ts
    slack_client.chat_postMessage(message_params(channel_rid, thread))
  rescue Slack::Web::Api::Errors::SlackError
    fallback_to_dm_response
  end

  def parent_ts
    slack_client.conversations_replies(
      channel: channel_rid,
      ts: message_ts || event_ts
    )[:messages].first[:thread_ts]
  end

  def respond_in_convo(channel = nil, thread = thread_ts)
    slack_client.chat_postMessage(message_params(channel, thread))
  rescue Slack::Web::Api::Errors::SlackError
    respond_not_in_channel
  end

  def message_params(channel, thread = nil)
    is_inline = first_tip.present? && channel == first_tip.from_channel_rid
    {
      channel: channel || channel_rid,
      thread_ts: thread,
      unfurl_links: false,
      unfurl_media: false,
      text: unformatted_text(is_inline) # Desktop notification (blocks take precedent in client)
    }.merge(response_params(is_inline)).compact
  end

  def unformatted_text(is_inline)
    return 'A random usage hint' if mode == :hint
    return alt_text if image.present?
    chat_response_text(is_inline:).gsub(/(_\s+)|(\s+_)|(\A_)|(_\z)/, ' ').strip
  end

  def response_params(is_inline)
    image_param || text_param(is_inline)
  end

  def text_param(is_inline) # rubocop:disable Metrics/MethodLength
    return text if text.is_a?(Hash) # { blocks: ... } for Slack formatting
    {
      blocks: [
        {
          type: :section,
          text: {
            type: :mrkdwn,
            text: chat_response_text(is_inline:)
          }
        }
      ]
    }
  end

  def image_param
    return if image.blank?
    {
      blocks: [
        {
          type: 'image',
          image_url: image,
          alt_text:
        }
      ]
    }
  end

  def alt_text
    @alt_text ||= "#{App.app_name} response image"
  end

  def respond_dm(to_profile_rid)
    post_params = message_params(to_profile_rid).merge(as_user: true)
    slack_client.chat_postMessage(post_params)
  rescue Slack::Web::Api::Errors::InvalidBlocks => e
    Honeybadger.notify(e, parameters: post_params)
  end

  def respond_ephemeral(to_profile_rid)
    slack_client.chat_postEphemeral \
      channel: channel_rid,
      user: to_profile_rid,
      text: chat_response_text
  rescue Slack::Web::Api::Errors::SlackError # Bot not in channel
    respond_dm(to_profile_rid)
  end

  def respond_not_in_channel
    @text = ":#{App.error_emoji}: #{I18n.t('slack.not_in_channel', channel: "<##{channel_rid}>")}"
    respond_dm(profile_rid)
  end

  def replace_message
    slack_client.chat_update \
      message_params(replace_channel_rid).merge(ts: replace_ts)
  rescue Slack::Web::Api::Errors::FatalError # Unclear why this appears occasionally
    false
  end

  def delete_message
    slack_client.chat_delete(channel: channel_rid, ts: replace_ts)
  end

  def fast_ack_text
    return unless mode == :fast_ack
    word = sender.announce_tip_sent? ? "#{sender.display_name}'s" : 'a'
    "_Working on #{word} request..._"
  end

  def render_tip_modal
    slack_client.views_open \
      trigger_id:,
      view: Slack::Modals::Tip.call(team_rid:)
  end

  def render_prefs_modal
    slack_client.views_open \
      trigger_id:,
      view: Slack::Modals::Preferences.call(team_rid:, profile_rid:)
  end

  def post_response_channel_rid
    post_response[:channel]
  end

  def post_response_ts
    post_response[:ts]
  end

  def recipients
    @recipients ||= tips.map(&:to_profile).uniq
  end

  def response_action
    return response_mode unless response_mode == :adaptive
    case action
    when :message, :submit_tip_modal then :convo
    when :reaction_added, :reply_tip then :reply
    else :convo # rubocop:disable Lint/DuplicateBranch
    end
  end

  def slack_client
    @slack_client ||= Slack::SlackApi.client(team_rid:)
  end
end
