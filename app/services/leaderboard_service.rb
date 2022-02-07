# frozen_string_literal: true
class LeaderboardService < Base::Service
  option :team, default: proc {}
  option :profile, default: proc {}
  option :count, default: proc { App.default_leaderboard_size }
  option :offset, default: proc {}
  option :givingboard, default: proc { false }

  def call
    @team ||= profile.team
    @count = 1_000 if count == 'all'

    return if leaderboard_cache.blank?

    leaderboard_snippet
  end

  private

  def leaderboard_snippet
    LeaderboardSnippet.new(leaderboard_cache.updated_at, snippet_profiles)
  end

  def snippet_profiles
    leaderboard_cache.profiles[start_idx..end_idx]
  end

  def end_idx
    start_idx + count - 1
  end

  def start_idx
    offset.presence || contextual_start_idx
  end

  def contextual_start_idx
    return 0 if count >= leaderboard_cache.profiles.size
    [0, profile_idx - (count.to_f / 2).floor].max
  end

  def profile_idx
    leaderboard_cache.profiles.index { |prof| prof.slug == profile&.slug } || 0
  end

  def leaderboard_cache
    @leaderboard_cache ||= Cache::Leaderboard.new(team.id, givingboard).get
  end
end
