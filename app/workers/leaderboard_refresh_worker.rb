# frozen_string_literal: true
class LeaderboardRefreshWorker
  include Sidekiq::Worker

  attr_reader :team_id, :giving_board, :jab_board

  def perform(team_id, giving_board = false, jab_board = false)
    @team_id = team_id
    @giving_board = giving_board
    @jab_board = jab_board

    Cache::Leaderboard.new(team_id, giving_board, jab_board).set(leaderboard_data)
  end

  private

  def leaderboard_data
    {
      updated_at: Time.current.to_i,
      profiles: sorted_ranked_profile_data
    }
  end

  def sorted_ranked_profile_data # rubocop:disable Metrics/MethodLength
    rank = 0
    points = 0
    timestamp = nil

    profiles = sorted_active_profiles.map do |prof|
      last_timestamp = last_timestamp_for(prof)
      if points != prof.points || timestamp != last_timestamp
        rank += 1
        points = prof.points
        timestamp = last_timestamp
      end

      profile_data(prof, rank, last_timestamp)
    end
    profiles.compact.sort_by { |prof| [prof.rank, prof.display_name] }
  end

  def profile_data(prof, rank, timestamp) # rubocop:disable Metrics/MethodLength
    return if (points = prof.send(value_col)).zero?
    LeaderboardProfile.new \
      id: prof.id,
      rank:,
      previous_rank: rank, # TODO: Re-enable later
      slug: prof.slug,
      link: prof.dashboard_link,
      display_name: prof.display_name,
      real_name: prof.real_name,
      points:,
      last_timestamp: timestamp.to_i,
      avatar_url: prof.avatar_url
  end

  def value_col
    @value_col ||=
      if giving_board
        jab_board ? :jabs_sent : :points_sent
      elsif jab_board
        :jabs_received
      else
        team.deduct_jabs? ? :balance : :points_received
      end
  end

  def verb
    @verb ||= giving_board ? 'sent' : 'received'
  end

  def last_timestamp_col
    @last_timestamp_col ||= "last_tip_#{verb}_at"
  end

  def sorted_active_profiles
    team.profiles
        .active
        .where.not(last_timestamp_col => nil)
        .order(value_col => :desc, last_timestamp_col => :desc)
  end

  def last_timestamp_for(prof)
    prof.send(last_timestamp_col)
  end

  def team
    @team ||= Team.find(team_id)
  end
end
