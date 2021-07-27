# frozen_string_literal: true
class Commands::Stats < Commands::Base
  def call
    respond
  end

  private

  def respond
    OpenStruct.new(mode: :public, text: response_text)
  end

  def base_text # rubocop:disable Metrics/AbcSize
    ary = [stats_title]
    ary << rank_fragment
    ary << level_fragment if team.enable_levels?
    ary << karma_received_fragment
    ary << karma_given_fragment
    ary << token_fragment if team.throttle_tips? && requested_profile.rid == profile_rid
    ary << streak_fragment if team.enable_streaks?
    ary << web_profile_fragment
    ary.compact.join("\n")
  end

  def token_fragment
    return '*Tokens:* Unlimited' if requested_profile.infinite_tokens?
    <<~TEXT.chomp
      *Tokens:* #{points_format(requested_profile.token_balance)} (receiving #{team.token_quantity} tokens in #{next_token_dispersal})
    TEXT
  end

  def web_profile_fragment
    "*Profile:* <#{requested_profile.web_link}>"
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
      *Stats for #{requested_profile.link}*
    TEXT
  end

  def karma_received_fragment
    <<~TEXT.chomp
      *#{App.points_term.titleize}:* #{points_format(requested_profile.karma)}
    TEXT
  end

  def karma_given_fragment
    <<~TEXT.chomp
      *Given:* #{points_format(requested_profile.karma_sent)}
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
