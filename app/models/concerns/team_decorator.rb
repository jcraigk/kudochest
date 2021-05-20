# frozen_string_literal: true
module TeamDecorator
  extend ActiveSupport::Concern

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: api_key)
  end

  def level_karma_table
    last_karma = 0
    rows = level_karma_map.map do |level, karma|
      delta = karma - last_karma
      last_karma = karma
      level_karma_table_row(level, karma, delta)
    end
    (level_karma_table_title_rows + rows).join("\n")
  end

  def karma_emoj
    ":#{karma_emoji}:"
  end

  def infinite_profiles_sentence
    profile_links =
      profiles.active
              .where(infinite_tokens: true)
              .sort_by(&:display_name)
              .map(&:link)

    return 'None' if profile_links.empty?
    profile_links.to_sentence
  end

  def level_karma_map
    (1..max_level).index_with { |level| LevelToKarmaService.call(team: self, level: level) }
  end

  def workspace_noun
    case platform
    when 'slack' then 'workspace'
    when 'discord' then 'guild'
    end
  end

  def custom_emoj
    case platform
    when 'slack' then karma_emoj
    when 'discord' then "<:#{App.discord_emoji}:#{karma_emoji}>"
    end
  end

  def plat
    platform.to_s.titleize
  end

  def config
    Cache::TeamConfig.call(rid)
  end

  def help_url
    case platform
    when 'slack' then App.help_url
    when 'discord' then "#{App.help_url}/discord"
    end
  end

  private

  def level_karma_table_title_rows
    [
      'Level  Karma  Delta',
      '-----  -----  -----'
    ]
  end

  def level_karma_table_row(level, karma, delta)
    format(
      '%<level>-5d  %<karma>-5d  %<delta>-5d',
      level: level,
      karma: karma,
      delta: delta
    ).strip
  end
end
