# frozen_string_literal: true
class Commands::Report < Commands::Base
  def call
    respond
  end

  private

  def respond
    ChatResponse.new(mode: :public, text: response_text)
  end

  def team_ary # rubocop:disable Metrics/AbcSize
    [].tap do |ary|
      ary << team_points_str
      ary << team_jabs_str if team_data.jabs_given.positive?
      ary << top_givers_str if team_data.top_givers.any?
      ary << top_recipients_str if team_data.top_recipients.any?
      ary << team_events_str if team_data.leveling_sentence.present?
      ary << loot_claim_str if team.enable_loot?
    end
  end

  def profile_ary # rubocop:disable Metrics/AbcSize
    [].tap do |ary|
      ary << points_received_str
      ary << points_given_str
      ary << jabs_received_str if profile_data.jabs_received.positive?
      ary << jabs_given_str if profile_data.jabs_received.positive?
      ary << profile_events_str if profile_data.leveling_sentence.present?
    end
  end

  def team_report?
    requested_profile_rid.blank?
  end

  def report_title
    start_time = num_days.days.ago
    format = start_time.strftime('%b') == Time.current.strftime('%b') ? '%-d' : '%b %-d'
    date_str = "#{start_time.strftime('%b %-d')} - #{Time.current.strftime(format)}"
    "*Report for #{entity_name} covering #{date_str}*"
  end

  def entity_name
    team_report? ? team.name : requested_profile.dashboard_link
  end

  def response_text
    ary = [report_title]
    ary += team_report? ? team_ary : profile_ary
    ary.flatten.join("\n")
  end

  def team_points_str
    txt = team_data.points_given.positive? ? team_points_detail : 'None'
    "#{team.point_emoj} *#{App.points_term.titleize}:* #{txt}"
  end

  def team_points_detail
    "#{points_format(team_data.points_given)} from " \
      "#{pluralize(team_data.point_givers.size, 'user')} to " \
      " #{pluralize(team_data.point_recipients.size, 'user')}"
  end

  def team_jabs_str
    <<~TEXT.chomp
      #{team.jab_emoj} *#{App.jabs_term.titleize}:* #{points_format(team_data.jabs_given)} from #{pluralize(team_data.jab_givers.size, 'user')} to #{pluralize(team_data.jab_recipients.size, 'user')}
    TEXT
  end

  def top_givers_str
    sentence =
      team_data.top_givers
               .map do |data|
                 "#{data.profile.dashboard_link} (#{points_format(data.quantity)})"
               end.to_sentence
    ":point_left: *Top Benefactors:* #{sentence}"
  end

  def top_recipients_str
    sentence =
      team_data.top_recipients
               .map do |data|
                 "#{data.profile.dashboard_link} (#{points_format(data.quantity)})"
               end.to_sentence
    ":point_right: *Top Recipients:* #{sentence}"
  end

  def team_events_str
    ":chart_with_upwards_trend: *Leveling:* #{team_data.leveling_sentence}"
  end

  def loot_claim_str
    ":cake: *Loot Claims:* #{team_data.loot_claims_sentence}"
  end

  def points_received_str
    profile_sentence \
      "#{team.point_emoj} #{App.points_term.titleize} Received",
      profile_data.points_received,
      profile_data.top_givers.map(&:profile),
      'from'
  end

  def points_given_str
    profile_sentence \
      "#{team.point_emoj} #{App.points_term.titleize} Given",
      profile_data.points_given,
      profile_data.top_recipients.map(&:profile)
  end

  def jabs_received_str
    profile_sentence \
      "#{team.jab_emoj} #{App.jabs_term.titleize} Received",
      profile_data.jabs_received,
      profile_data.jab_givers,
      'from'
  end

  def jabs_given_str
    profile_sentence \
      "#{team.jab_emoj} #{App.jabs_term.titleize} Given",
      profile_data.jabs_given,
      profile_data.jab_recipients
  end

  def profile_sentence(title, points, profs, word = 'to')
    sentence = profs.map(&:dashboard_link).to_sentence
    num = profs.size
    suffix = num.zero? ? nil : (num < 5 ? "(#{sentence})" : "including #{sentence}")
    txt = "*#{title}:* "
    txt +
      if points.positive?
        "#{points_format(points)} #{word} #{pluralize(num, 'user')} #{suffix}".strip
      else
        'None'
      end
  end

  def profile_events_str
    ":chart_with_upwards_trend: *Leveling:* #{profile_data.leveling_sentence}"
  end

  def team_data
    @team_data ||= Reports::TeamDigestService.call(team:, num_days:)
  end

  def profile_data
    @profile_data ||= Reports::ProfileDigestService.call(profile: requested_profile, num_days:)
  end

  # If user specifies user(s) after keyword, show the first one's stats
  # Default to the user themself if no user specified
  def requested_profile_rid
    words.first&.scan(PROFILE_REGEX[team.platform])&.map(&:first)&.first || me
  end

  def me
    profile_rid if words.first == 'me'
  end

  def requested_profile
    @requested_profile ||= team.profiles.find_by!(rid: requested_profile_rid)
  end

  def num_days
    words.last&.match?(/\A\d+\z/) ? words.last.to_i : Reports::BaseDigestService::NUM_DAYS
  end
end
