# frozen_string_literal: true
class Commands::Stats < Commands::Base
  def call
    respond
  end

  private

  def respond
    ChatResponse.new(mode: :public, text: response_text)
  end

  def base_text # rubocop:disable Metrics/AbcSize
    ary = [stats_title]
    ary << rank_fragment
    ary << level_fragment if team.enable_levels?
    ary << points_received_fragment
    if team.enable_jabs?
      ary << jabs_received_fragment
      ary << balance_fragment
    end
    ary << points_given_fragment
    ary << jabs_given_fragment if team.enable_jabs?
    ary << token_fragment if team.throttle_tips? && requested_profile.rid == profile_rid
    ary << streak_fragment if team.enable_streaks?
    ary.compact.join("\n")
  end

  def token_fragment
    return '*Tokens:* Unlimited' if requested_profile.infinite_tokens?
    <<~TEXT.chomp
      *Tokens:* #{points_format(requested_profile.token_balance)} (receiving #{team.token_quantity} tokens in #{next_token_dispersal})
    TEXT
  end

  def streak_fragment
    "*Giving Streak:* #{requested_profile.active_streak_sentence}"
  end

  def next_token_dispersal
    Time.use_zone(team.time_zone) do
      distance_of_time_in_words(Time.current, team.next_tokens_at)
    end
  end

  def stats_title
    <<~TEXT.chomp
      *Stats for #{requested_profile.profile_link}*
    TEXT
  end

  def points_received_fragment
    <<~TEXT.chomp
      *#{App.points_term.titleize} Received:* #{points_format(requested_profile.points)}
    TEXT
  end

  def jabs_received_fragment
    <<~TEXT.chomp
      *#{App.jabs_term.titleize} Received:* #{points_format(requested_profile.jabs)}
    TEXT
  end

  def balance_fragment
    <<~TEXT.chomp
      *Balance:* #{points_format(requested_profile.balance)}
    TEXT
  end

  def points_given_fragment
    <<~TEXT.chomp
      *#{App.points_term.titleize} Given:* #{points_format(requested_profile.points_sent)}
    TEXT
  end

  def jabs_given_fragment
    <<~TEXT.chomp
      *#{App.jabs_term.titleize} Given:* #{points_format(requested_profile.jabs_sent)}
    TEXT
  end

  def rank_fragment
    return if requested_profile.rank.blank?
    "*Leaderboard Rank:* #{number_with_delimiter(requested_profile.rank)}"
  end

  def level_fragment
    "*Level:* #{requested_profile.level}"
  end

  # If user specifies user(s) after keyword, show the first one's stats
  # Default to the user themself if no user specified
  def effective_rid
    text.scan(PROFILE_REGEX[team.platform]).map(&:first).first || profile_rid
  end

  def requested_profile
    @requested_profile ||= team.profiles.find_by!(rid: effective_rid)
  end
end
