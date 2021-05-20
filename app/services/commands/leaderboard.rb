# frozen_string_literal: true
class Commands::Leaderboard < Commands::Base
  def call
    respond_success
  end

  private

  def respond_success
    OpenStruct.new({ mode: :public }.merge(result))
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
    ResponseImageService.call(
      type: 'leaderboard',
      team_config: team.config,
      profile_data: profile_data,
      title: leaderboard_title
    )
  end

  def base_text
    if profile_data.none?
      return I18n.t('teams.leaderboard_empty', seconds: App.leaderboard_refresh_seconds)
    end
    [leaderboard_title, leaderboard_rows].join("\n")
  end

  def topic_suffix
    return if topic_id.blank?
    " for #{Topic.find(topic_id).name}"
  end

  def leaderboard_title
    @leaderboard_title ||=
      "*Top #{profile_count} Karma #{title_verb}#{topic_suffix}*".gsub(/\s+/, ' ')
  end

  def profile_count
    return if profile_data.count == 1
    number_with_delimiter(profile_data.count)
  end

  def leaderboard_rows
    profile_data.map do |prof|
      str = row(prof)
      str = "*#{str}*" if prof.id == profile.id
      str
    end.join("\n")
  end

  def row(prof)
    <<~TEXT.chomp
      #{prof.rank}. #{prof.link} - #{karma_format(prof.karma)} karma last #{verb} #{time_ago_in_words(Time.zone.parse(prof.last_timestamp))} ago
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
    team.config.topics.find { |topic| word.in?([topic.keyword, ":#{topic.emoji}:"]) }&.id
  end

  def givingboard?
    @givingboard ||= words.last&.in?(%w[giving giver givers sent gift gifts gifters])
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
    @profile_data ||= LeaderboardService.call(opts.compact).profiles
  end
end
