# frozen_string_literal: true
module ProfileDecorator
  include PointsHelper
  extend ActiveSupport::Concern

  def helpers
    ActionController::Base.helpers
  end

  def token_balance_sentence
    return 'no tokens remaining' if token_balance.zero?
    "#{points_format(token_balance)} tokens remaining"
  end

  def link
    "<#{PROF_PREFIX}#{rid}>"
  end

  def link_with_stat
    team.enable_levels? ? link_with_level : link_with_points
  end

  def link_with_level
    "#{link} (level #{level})"
  end

  def link_with_points
    "#{link} (#{points_format(points, label: true)})"
  end

  def webref
    helpers.tag.span(display_name_ref, class: 'chat-ref')
  end

  def webref_with_stat
    team.enable_levels? ? webref_with_level : webref_with_points
  end

  def webref_with_level
    "#{webref} (level #{level})"
  end

  def webref_with_points
    "#{webref} (#{points_format(points_received, label: true)})"
  end

  def long_name
    str = display_name_ref
    str += " (#{real_name})" if display_name != real_name
    str
  end

  def next_level_points_sentence
    return 'max level' if max_level?
    "#{points_format(points_required_for_next_level, label: true)} until level #{level + 1}"
  end

  def points_required_for_next_level
    return 0 if max_level?
    LevelToPointsService.call(team: team, level: next_level) - points_received
  end

  def level
    PointsToLevelService.call(team: team, points: points_received)
  end

  def next_level
    [level + 1, team.max_level].min
  end

  def max_level?
    level == team.max_level
  end

  def active_streak
    @active_streak ||= streak_date && next_streak_date >= today ? streak_count : 0
  end

  def active_streak_sentence
    str = helpers.pluralize(active_streak, 'day')
    return str if active_streak.zero?
    str + ", next target #{next_streak_date.strftime('%b %-d')} (#{next_streak_date_distance})"
  end

  def rank
    @rank ||= LeaderboardService.call(profile: self, count: 1)&.profiles&.first&.rank
  end

  def next_streak_date
    @next_streak_date ||= calculate_next_streak_date
  end

  def next_streak_date_distance
    Time.use_zone(team.time_zone) do
      case next_streak_date
      when today then 'today'
      when tomorrow then 'tomorrow'
      else "on #{next_streak_date.strftime('%A')}"
      end
    end
  end

  def web_url
    "#{App.base_url}/profiles/#{slug}"
  end

  def web_link
    team.platform.slack? ? slack_web_link : web_url
  end

  def slack_web_link
    "#{web_url}|View web profile"
  end

  def points_unclaimed
    points_received - points_claimed
  end

  private

  def calculate_next_streak_date
    return today unless (date = streak_date)
    loop do
      date = date.advance(days: 1)
      return date if working_day?(date)
    end
  end

  def display_name_ref
    "#{PROF_PREFIX}#{display_name}"
  end

  def working_day?(date)
    date.strftime('%A').downcase.in?(team.work_days)
  end

  def today
    @today ||= Time.use_zone(team.time_zone) { Time.zone.today }
  end

  def tomorrow
    @tomorrow ||= Time.use_zone(team.time_zone) { Time.zone.tomorrow }
  end
end
