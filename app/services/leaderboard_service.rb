# frozen_string_literal: true
class LeaderboardService < Base::Service
  option :team, default: proc {}
  option :profile, default: proc {}
  option :count, default: proc { 10 }
  option :offset, default: proc {}
  option :topic_id, default: proc {}
  option :givingboard, default: proc { false }
  option :previous_timestamp, default: proc { App.leaderboard_trend_days.days.ago }

  def call
    @team ||= profile.team
    @count = 1_000 if count == 'all'

    leaderboard_snippet
  end

  private

  def leaderboard_snippet
    OpenStruct.new(
      updated_at: leaderboard_cache.updated_at,
      profiles: snippet_profiles
    )
  end

  def snippet_profiles
    @snippet_profiles ||= leaderboard_cache.profiles[start_idx..end_idx]
  end

  def end_idx
    @end_idx ||= start_idx + count - 1
  end

  def start_idx
    @start_idx ||= offset.presence || contextual_start_idx
  end

  def contextual_start_idx
    [0, profile_idx - (count.to_f / 2).floor].max
  end

  def profile_idx
    @profile_idx ||= leaderboard_cache.profiles.index { |prof| prof.slug == profile&.slug } || 0
  end

  def leaderboard_cache
    @leaderboard_cache ||=
      Rails.cache.fetch(cache_key, ttl: App.leaderboard_refresh_seconds.seconds) do
        leaderboard_data
      end
  end

  def leaderboard_data
    OpenStruct.new(
      updated_at: Time.current,
      profiles: sorted_ranked_profile_data
    )
  end

  def last_topic_timestamp_for(prof_id)
    Tip.where(profile_col => prof_id)
       .where(topic_id: topic_id)
       .order(created_at: :desc)
       .pick(:created_at)
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

    profiles.sort_by { |prof| [prof.rank, prof.display_name] }
  end

  def profile_data(prof, rank, timestamp) # rubocop:disable Metrics/MethodLength
    points = effective_points(prof)
    percent = percent_share(prof, points)
    OpenStruct.new(
      id: prof.id,
      rank: rank,
      previous_rank: previous_rank_for(prof),
      slug: prof.slug,
      link: prof.link,
      display_name: prof.display_name,
      real_name: prof.real_name,
      points: points,
      percent_share: percent,
      last_timestamp: timestamp.to_s,
      avatar_url: prof.avatar_url
    )
  end

  def effective_points(prof)
    if topic_id.present?
      @topic_tip_data.find { |data| data.profile_id == prof.id }&.total
    else
      givingboard ? prof.points_sent : prof.points_received
    end
  end

  def percent_share(prof, points)
    return 0 if prof.team.points_sent.zero?
    total = topic_id.present? ? topic_total : prof.team.points_sent
    (points / total.to_f) * 100
  end

  def topic_total
    Tip.where(topic_id: topic_id).sum(:quantity)
  end

  def cache_key
    "leaderboard/#{team.id}/#{leaderboard_type}/#{topic_id}"
  end

  def leaderboard_type
    @leaderboard_type ||= givingboard ? 'given' : 'received'
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
    topic_id.present? ? topic_active_profiles : general_active_profiles
  end

  def general_active_profiles
    team.profiles
        .active
        .where("#{points_col} > ?", 0)
        .order(points_col => :desc, last_timestamp_col => :asc)
  end

  def topic_active_profiles
    ranked_profile_ids = topic_tip_data.map(&:profile_id)
    profiles = Profile.where(id: ranked_profile_ids)
    ranked_profile_ids.map { |profile_id| profiles.find { |prof| prof.id == profile_id } }
  end

  def topic_tip_data
    @topic_tip_data ||=
      Tip.where(topic_id: topic_id)
         .where(from_profile_id: Profile.active.where(team: team).select(:id))
         .select("#{profile_col} AS profile_id", 'SUM(quantity) AS total')
         .group(:profile_id)
         .sort_by(&:total)
         .reverse
  end

  def previous_rank_for(prof)
    previous_leaderboard.find { |row| row.id == prof.id }.rank
  end

  def last_timestamp_for(prof)
    if topic_id.present?
      last_topic_timestamp_for(prof.id)
    else
      prof.send(last_timestamp_col)
    end
  end

  def previous_leaderboard # rubocop:disable Metrics/MethodLength
    rank = 0
    points = 0
    timestamp = nil

    previous_point_sums.sort_by(&:points).reverse_each.with_object([]) do |prof, ary|
      last_timestamp = last_timestamp_for(prof)
      if points != prof.points || timestamp != last_timestamp
        rank += 1
        points = prof.points
        timestamp = last_timestamp
      end

      ary << OpenStruct.new(id: prof.id, rank: rank)
    end
  end

  def previous_point_sums
    sorted_active_profiles.map do |prof|
      OpenStruct.new(
        id: prof.id,
        points: previous_points_for(prof)
      )
    end
  end

  def previous_points_for(prof)
    assoc = givingboard ? 'tips_sent' : 'tips_received'
    rel = prof.send(assoc)
    rel = rel.where(topic_id: topic_id) if topic_id.present?
    rel.where('created_at < ?', previous_timestamp).sum(:quantity)
  end
end
