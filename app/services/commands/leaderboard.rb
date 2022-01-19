# frozen_string_literal: true
class Commands::Leaderboard < Commands::Base
  GIVING_WORDS = %w[giving giver givers gift gifts gifters sent].freeze

  def call
    respond_success
  end

  private

  def respond_success
    ChatResponse.new({ mode: :public }.merge(result))
  end

  def result
    team.response_theme.start_with?('gif_') ? image_response : text_response
  end

  def text_response
    { text: response_text }
  end

  def image_response
    { image: response_image }
  end

  def response_image
    ResponseImageService.call \
      type: 'leaderboard',
      team_config: team.config,
      profile_data:,
      title:
  end

  def base_text
    return I18n.t('teams.leaderboard_empty') if profile_data.blank?
    [title, rows].join("\n")
  end

  def topic_suffix
    return if topic_id.blank?
    " for #{Topic.find(topic_id).name}"
  end

  def title
    @title ||=
      "*Top #{profile_count} #{App.points_term.titleize} #{title_verb}#{topic_suffix}*".squish
  end

  def profile_count
    return if profile_data.count == 1
    number_with_delimiter(profile_data.count)
  end

  def rows
    profile_data.map do |prof|
      str = row(prof)
      str = "*#{str}*" if prof.id == profile.id
      str
    end.join("\n")
  end

  def row(prof)
    timeframe =
      time_ago_in_words \
        Time.use_zone(team.time_zone) { Time.at(prof.last_timestamp).utc }
    <<~TEXT.chomp
      #{prof.rank}. #{prof.link} - #{points_format(prof.points, label: true)} (most recently #{timeframe} ago)
    TEXT
  end

  def verb
    givingboard? ? 'given' : 'earned'
  end

  def title_verb
    givingboard? ? 'Givers' : 'Earners'
  end

  def count
    words.first&.to_i if words.first&.match?(/\d+/)
  end

  def words
    @words ||= text.split(/\s+/)
  end

  def requested_profile
    profile if words.last == 'me'
  end

  # `top kindness givers`
  # `top :fire:`
  def topic_id
    word = givingboard? ? words[-1] : words.last
    team.config.topics.find { |t| word.in?([t.keyword, ":#{t.emoji}:"]) }&.id
  end

  def givingboard?
    @givingboard ||= words.last&.in?(GIVING_WORDS)
  end

  def opts
    {
      team: team,
      count: count,
      profile: requested_profile,
      givingboard: givingboard?,
      topic_id: topic_id
    }
  end

  def profile_data
    @profile_data ||= LeaderboardService.call(**opts.compact)&.profiles
  end
end
