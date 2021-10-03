# frozen_string_literal: true
class Commands::Admin < Commands::Base
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include PointsHelper

  def call
    respond_success
  end

  private

  def respond_success
    OpenStruct.new(mode: :private, text: response_text)
  end

  def base_text
    <<~TEXT.chomp
      #{throttle_points_text}
      #{increment_text}
      #{topic_text}
      #{notes_text}
      #{emoji_text}
      #{level_text}
      #{streak_text}
      #{time_text}
      *Administrator:* #{team_admin}
    TEXT
  end

  def topic_text
    str = "*Topics Enabled:* #{boolean_str(team.enable_topics?)}"
    return str unless team.enable_topics?
    str += "\n*Topic Required:* #{boolean_str(team.require_topic?)}"
    str + "\n*Active Topics:* #{team.topics.active.count}"
  end

  def notes_text
    "*Notes:* #{team.tip_notes.titleize}"
  end

  def increment_text
    <<~TEXT.chomp
      *Minimum Increment:* #{points_format(team.tip_increment, label: true)}
    TEXT
  end

  def time_text
    <<~TEXT.chomp
      *Time Zone:* #{long_time_zone}
      *Work Days:* #{work_days}
      *Work Start Day:* #{team.week_start_day.titleize}
    TEXT
  end

  def emoji_text
    txt = "*Emoji Enabled:* #{boolean_str(team.enable_emoji?)}"
    return txt unless team.enable_emoji?

    "#{txt}\n*Emoji Value:* #{points_format(team.emoji_quantity, label: true)}" \
      "\n*#{App.points_term.titleize} Emoji:* #{team.tip_emoj}" \
      "\n*Ditto Emoji:* #{team.ditto_emoj}"
  end

  def level_text
    txt = "*Leveling Enabled:* #{boolean_str(team.enable_levels?)}"
    return txt unless team.enable_levels?
    txt + level_detail_text
  end

  def level_detail_text
    <<~TEXT.chomp

      *Maximum Level:* #{team.max_level}
      *Required for Max Level:* #{points_format(team.max_level_points, label: true)}
      *Progression Curve:* #{team.level_curve.titleize}
    TEXT
  end

  def throttle_points_text
    txt = "*Throttle #{App.points_term.titleize}:* #{boolean_str(team.throttle_tips)}"
    return txt unless team.throttle_tips
    txt + throttle_detail_text
  end

  def throttle_detail_text
    <<~TEXT.chomp

      *Exempt Users:* #{team.infinite_profiles_sentence}
      *Token Dispersal Hour:* #{num_to_hour(team.action_hour)}
      *Token Dispersal Frequency:* #{team.token_frequency.titleize}
      *Token Dispersal Quantity:* #{number_with_delimiter(team.token_quantity)}
      *Token Max Balance:* #{number_with_delimiter(team.token_max)}
    TEXT
  end

  def streak_text
    txt = "*Streaks Enabled:* #{boolean_str(team.enable_streaks?)}"
    return txt unless team.enable_streaks?
    txt + <<~TEXT.chomp

      *Streak Duration:* #{pluralize(team.streak_duration, 'day')}
      *Streak Reward:* #{points_format(team.streak_reward, label: true)}
    TEXT
  end

  def boolean_str(val)
    val ? 'Yes' : 'No'
  end

  def work_days
    team.work_days.map(&:titleize).join(', ')
  end

  def team_admin
    return owner.email if owner_profile_link.blank?
    "#{owner_profile_link} (#{owner.email})"
  end

  def owner
    @owner ||= team.owning_user
  end

  def owner_profile_link
    @owner_profile_link ||= owner.profiles.where(team: team).first&.link
  end

  def long_time_zone
    ActiveSupport::TimeZone.all.find { |tz| tz.name == team.time_zone }.to_s
  end
end
