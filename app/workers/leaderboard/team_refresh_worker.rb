# frozen_string_literal: true
class Leaderboard::TeamRefreshWorker
  include Sidekiq::Worker
  sidekiq_options queue: :leaderboard,
                  lock: :until_executed,
                  lock_ttl: 1.hour

  attr_reader :team_id, :givingboard

  def perform(team_id, givingboard = false)
    @team_id = team_id
    @givingboard = givingboard

    Cache::Leaderboard.new(team_id, givingboard).set(leaderboard_data)
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

    profiles.sort_by { |prof| [prof[:rank], prof[:display_name]] }
  end

  def profile_data(prof, rank, timestamp) # rubocop:disable Metrics/MethodLength
    points = prof.send("points_#{verb}")
    percent = percent_share(prof, points)
    {
      id: prof.id,
      rank: rank,
      # previous_rank: previous_rank_for(prof), # TODO: Re-enable later
      previous_rank: rank,
      slug: prof.slug,
      link: prof.profile_link,
      display_name: prof.display_name,
      real_name: prof.real_name,
      points: points,
      percent_share: percent,
      last_timestamp: timestamp.to_i,
      avatar_url: prof.avatar_url
    }
  end

  def percent_share(prof, points)
    return 0 if prof.team.points_sent.zero?
    (points / prof.team.points_sent.to_f) * 100
  end

  def points_col
    @points_col ||= "points_#{verb}"
  end

  def verb
    @verb ||= givingboard ? 'sent' : 'received'
  end

  def last_timestamp_col
    @last_timestamp_col ||= "last_tip_#{verb}_at"
  end

  def profile_col
    @profile_col = givingboard ? :from_profile_id : :to_profile_id
  end

  def sorted_active_profiles
    team.profiles
        .active
        .where("#{points_col} > ?", 0)
        .order(points_col => :desc, last_timestamp_col => :asc)
  end

  def last_timestamp_for(prof)
    prof.send(last_timestamp_col)
  end

  # def previous_rank_for(prof)
  #   previous_leaderboard.find { |row| row.id == prof.id }.rank
  # end
  #
  # def previous_leaderboard
  #   rank = 0
  #   points = 0
  #   timestamp = nil
  #
  #   previous_point_sums.sort_by(&:points).reverse_each.with_object([]) do |prof, ary|
  #     last_timestamp = last_timestamp_for(prof)
  #     if points != prof.points || timestamp != last_timestamp
  #       rank += 1
  #       points = prof.points
  #       timestamp = last_timestamp
  #     end
  #
  #     ary << OpenStruct.new(id: prof.id, rank: rank)
  #   end
  # end
  #
  # def previous_point_sums
  #   sorted_active_profiles.map do |prof|
  #     OpenStruct.new(
  #       id: prof.id,
  #       points: previous_points_for(prof)
  #     )
  #   end
  # end
  #
  # def previous_points_for(prof)
  #   prof.send(givingboard ? 'tips_sent' : 'tips_received')
  #       .where('created_at < ?', App.leaderboard_trend_days.days.ago)
  #       .sum(:quantity)
  # end

  def team
    @team ||= Team.find(team_id)
  end
end
