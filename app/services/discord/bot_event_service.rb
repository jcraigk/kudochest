# frozen_string_literal: true
class Discord::BotEventService < Base::Service
  option :bot

  def call # rubocop:disable Metrics/MethodLength
    listen_for_reaction_add
    listen_for_reaction_remove
    listen_for_message

    listen_for_server_update
    listen_for_server_delete

    listen_for_member_join
    listen_for_member_leave
    listen_for_member_update

    listen_for_channel_create
    listen_for_channel_delete

    listen_for_role_create
    listen_for_role_update
    listen_for_role_delete
  end

  private

  def listen_for_channel_create
    bot.channel_create do |event|
      next unless (team_rid = event.server&.id&.to_s) # Appears when DMing a user (?!)
      ChannelSyncWorker.perform_async(team_rid)
    end
  end

  def listen_for_channel_delete
    bot.channel_delete do |event|
      ChannelSyncWorker.perform_async(event.server.id.to_s)
    end
  end

  def listen_for_role_create
    bot.server_role_create do |event|
      SubteamSyncWorker.perform_async(event.server.id.to_s)
    end
  end

  def listen_for_role_update
    bot.server_role_update do |event|
      SubteamSyncWorker.perform_async(event.server.id.to_s)
    end
  end

  def listen_for_role_delete
    bot.server_role_delete do |event|
      SubteamSyncWorker.perform_async(event.server.id.to_s)
    end
  end

  def listen_for_member_join
    bot.member_join do |event|
      TeamSyncWorker.perform_async(event.server.id.to_s)
    end
  end

  def listen_for_member_leave
    bot.member_leave do |event|
      TeamSyncWorker.perform_async(event.server.id.to_s)
    end
  end

  def listen_for_member_update
    bot.member_update do |event|
      TeamSyncWorker.perform_async(event.server.id.to_s) # Profile attributes
    end
  end

  def listen_for_server_update
    bot.server_update do |event|
      avatar_url =
        "#{App.discord_cdn_base}/icons/#{event.server.id}/#{event.server.icon_id}.png?size=256"
      TeamUpdateWorker.perform_async(event.server.id.to_s, event.server.name, avatar_url)
    end
  end

  def listen_for_server_delete
    bot.server_delete do |event|
      payload = { team_rid: event.server&.to_s, action: 'app_uninstalled' }.to_json
      EventWorker.perform_async(payload)
    end
  end

  def listen_for_reaction_add
    bot.reaction_add do |event|
      handle_emoji_event(event, 'added')
    end
  end

  def listen_for_reaction_remove
    bot.reaction_remove do |event|
      handle_emoji_event(event, 'removed')
    end
  end

  def listen_for_message # rubocop:disable Metrics/AbcSize
    bot.message do |event|
      next event.respond(no_dm_support) if (team_rid = event.server&.id.to_s).blank?
      next unless (config = Cache::TeamConfig.call(team_rid))[:active]
      matches = MessageScanner.call(event.message.content, config)
      payload = message_payload(team_rid, config, event).merge(matches:).to_json
      EventWorker.perform_async(payload)
    end
  end

  def sanitized_text(event, config)
    event.text
         .gsub(/#{App.discord_command}/i, '')
         .gsub(bot_rid(config), '')
         .gsub(bot_subteam_rid(config), '')
         .strip
  end

  def origin(event, config)
    if event.text
            .start_with?(
              /#{App.discord_command}/i,
              bot_rid(config),
              bot_subteam_rid(config)
            )
      'command'
    else
      'channel'
    end
  end

  def bot_rid(config)
    "<#{SUBTEAM_PREFIX[:discord]}#{config[:app_profile_rid]}>"
  end

  def bot_subteam_rid(config)
    "<#{SUBTEAM_PREFIX[:discord]}#{config[:app_subteam_rid]}>"
  end

  def handle_emoji_event(event, verb)
    return unless relevant_emoji?(event.emoji.name)
    team_rid = event.server&.id.to_s
    return unless (config = Cache::TeamConfig.call(team_rid))[:active]
    payload = emoji_payload(team_rid, config, event, verb).to_json
    EventWorker.perform_async(payload)
  end

  def emoji_payload(team_rid, config, event, verb)
    {
      origin: 'channel',
      action: "reaction_#{verb}",
      message_ts: event.message.id.to_s,
      emoji: event.emoji.name
    }.merge(base_payload(team_rid, config, event)).tap do |hash|
      next unless verb == 'added'
      hash.merge!(to_profile_rid: event.message.author.id.to_s)
    end
  end

  def message_payload(team_rid, config, event)
    {
      action: 'message',
      text: sanitized_text(event, config),
      origin: origin(event, config)
    }.merge(base_payload(team_rid, config, event))
  end

  def base_payload(team_rid, config, event)
    {
      platform: 'discord',
      team_rid: team_rid,
      config:,
      is_bot_dm: false,
      channel_name: event.channel.name,
      channel_rid: event.channel.id.to_s,
      event_ts: event.message.id.to_s,
      profile_rid: event.user.id.to_s
    }
  end

  def no_dm_support
    ":#{App.error_emoji}: " \
      "#{I18n.t('errors.no_dm_support', url: "<#{App.help_url}>", cmd: App.base_command)}"
  end

  def relevant_emoji?(emoji)
    emoji.in?(standard_emojis) || topic_emoji?(emoji)
  end

  def standard_emojis
    [App.discord_point_emoji, App.discord_jab_emoji, App.discord_ditto_emoji]
  end

  def topic_emoji?(emoji)
    config[:enable_topics] && topic_id(emoji).present?
  end

  def topic_id(emoji)
    config[:topics].find { |topic| topic[:emoji] == emoji }&.dig(:id)
  end
end
