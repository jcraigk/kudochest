# frozen_string_literal: true
class Commands::Leaderboard < Commands::Base
  GIVING_WORDS = %w[giving giver givers gift gifts gifters sent benefactors bullies].freeze
  JAB_WORDS = [App.jab_term, App.jabs_term] + %w[losers].freeze

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
      config: team.config,
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
      "*Top #{profile_count} #{title_point_term} #{title_verb}#{topic_suffix}*".squish
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
      #{prof.rank}. #{prof.link} - #{points_format(prof.points)} (#{timeframe} ago)
    TEXT
  end

  def title_point_term
    (jab_board ? App.jab_term : App.point_term).titleize
  end

  def title_verb
    giving_board ? 'Givers' : 'Earners'
  end

  def count
    words.first&.to_i if words.first&.match?(/\d+/)
  end

  def requested_profile
    profile if words.last == 'me'
  end

  # `top kindness givers`
  # `top :fire:`
  def topic_id
    word = giving_board ? words[-1] : words.last
    team.config[:topics].find { |t| word.in?([t[:keyword], ":#{t[:emoji]}:"]) }&.dig(:id)
  end

  def giving_board
    @giving_board ||= (words.last(2) & GIVING_WORDS).any?
  end

  def jab_board
    @jab_board ||= (words.last(2) & JAB_WORDS).any?
  end

  def opts
    {
      team:,
      count:,
      profile: requested_profile,
      giving_board:,
      jab_board:,
      topic_id:
    }
  end

  def profile_data
    @profile_data ||= LeaderboardPageService.call(**opts.compact)&.profiles
  end
end
