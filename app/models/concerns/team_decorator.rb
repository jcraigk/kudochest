# frozen_string_literal: true
module TeamDecorator
  extend ActiveSupport::Concern

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: api_key)
  end

  def levels_table
    last_points = 0
    rows = level_points_map.map do |level, points|
      delta = points - last_points
      last_points = points
      levels_table_row(level, points, delta)
    end
    (levels_table_titles + rows).join("\n")
  end

  def tip_emoj
    ":#{tip_emoji}:"
  end

  def ditto_emoj
    ":#{ditto_emoji}:"
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

  def level_points_map
    (1..max_level).index_with { |level| LevelToPointsService.call(team: self, level:) }
  end

  def workspace_noun
    case platform
    when 'slack' then 'workspace'
    when 'discord' then 'guild'
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

  def levels_table_titles
    [
      "Level  #{App.points_term.titleize}  Delta",
      "-----  #{'-' * App.points_term.size}  -----"
    ]
  end

  def levels_table_row(level, points, delta)
    format(
      "%<level>-5d  %<points>-#{App.points_term.size}d  %<delta>-5d",
      level:,
      points:,
      delta:
    ).strip
  end
end
