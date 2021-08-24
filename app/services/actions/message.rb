# frozen_string_literal: true
class Actions::Message < Actions::Base
  include EntityReferenceHelper

  attr_reader :app_profile_rid, :app_subteam_rid, :team_rid, :profile_rid,
              :channel_rid, :text, :origin, :event_ts, :platform

  def call # rubocop:disable Metrics/AbcSize
    @app_profile_rid = params[:team_config][:app_profile_rid]
    @app_subteam_rid = params[:team_config][:app_subteam_rid]
    @channel_rid = params[:channel_rid]
    @event_ts = params[:event_ts]
    @origin = params[:origin]
    @profile_rid = params[:profile_rid]
    @team_rid = params[:team_rid]
    @text = params[:text]
    @platform = params[:platform].to_sym

    process_message
  end

  private

  def channel_name
    @channel_name ||= given_channel_name || fetch_channel_name
  end

  def given_channel_name
    params[:channel_name].presence
  end

  def fetch_channel_name
    return unless platform == :slack
    Slack::ChannelNameService.call(team: team, channel_rid: channel_rid).presence
  end

  def process_message
    return open_modal if modal_command?
    return call_command if keyword_detected?
    return handle_mentions if mention_matches.any?
    respond_bad_input if text_directed_at_app?
  end

  def text_directed_at_app?
    directed_at_app? && keyword.present?
  end

  def modal_command?
    origin == 'command' && keyword.blank?
  end

  def open_modal
    Cache::Modal.set("#{team_rid}/#{profile_rid}", channel_rid, channel_name)
    OpenStruct.new(mode: :modal)
  end

  def keyword_detected?
    directed_at_app? && command_key
  end

  def directed_at_app?
    @directed_at_app ||= origin.in?(%w[command bot-dm]) || bot_mention_prefix?
  end

  def handle_mentions
    MentionParser.call(
      team_rid: team_rid,
      profile_rid: profile_rid,
      event_ts: event_ts,
      channel_rid: channel_rid,
      channel_name: channel_name,
      matches: mention_matches,
      note: note
    )
  end

  def note
    NoteSanitizer.call(platform: platform, team_rid: team_rid, text: raw_note)
  end

  def raw_note
    text[mention_matches.last.end..].strip
  end

  def enable_emoji?
    params.dig(:team_config, :enable_emoji)
  end

  def mention_matches
    @mention_matches ||=
      sanitized_text.scan(mention_regex(platform, '[a-z0-9_]+'))
                    .map do |match|
                      last_match = extract_last_match(Regexp.last_match)
                      mention_match_struct(match, last_match)
                    end
  end

  def extract_last_match(last_match)
    last_match.end(5) ||
      last_match.end(4) ||
      last_match.end(3) ||
      last_match.end(2) ||
      last_match.end(1)
  end

  def sanitized_text
    text.tr("\u00A0", ' ') # Unicode space (from Slack)
  end

  def mention_match_struct(match, last_match_end)
    OpenStruct.new(
      profile_rid: match.second || match.first, # 'everyone' or entity RID match
      prefix_digits: match.third,
      suffix_digits: match.fifth,
      emoji_string: match.fourth,
      end: last_match_end
    )
  end

  def command_key
    @command_key ||= COMMAND_KEYWORDS.find do |k, v|
      k.to_s == keyword || v.include?(keyword)
    end&.first
  end

  def call_command
    "Commands::#{command_key.to_s.titleize}".constantize.call(
      team_rid: team_rid,
      profile_rid: profile_rid,
      text: opts_str
    )
  end

  def keyword
    @keyword ||= words.first&.downcase
  end

  def words
    @words ||= user_text.split(/\s+/)
  end

  def opts_str
    words[1..].join(' ')
  end

  def bot_mention_prefix?
    @bot_mention_prefix ||= text.start_with?(app_profile_ref, app_subteam_ref)
  end

  def user_text
    @user_text ||= text.gsub(/\A#{app_profile_ref}\s*/, '')
  end

  def app_profile_ref
    @app_profile_ref ||= "<#{PROFILE_PREFIX[platform]}#{app_profile_rid}>"
  end

  # Discord only
  def app_subteam_ref
    @app_subteam_ref ||= "<#{SUBTEAM_PREFIX[platform]}#{app_subteam_rid}>"
  end

  def respond_bad_input(message = nil)
    OpenStruct.new(
      mode: :error,
      text: message || bad_input_text
    )
  end

  def bad_input_text
    ":#{App.error_emoji}: #{I18n.t('errors.bad_command', text: user_text)}"
  end
end
