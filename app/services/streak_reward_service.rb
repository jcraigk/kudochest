class StreakRewardService < Base::Service
  option :profile
  option :event_ts

  def call
    @profile = profile

    return false unless team.enable_streaks?
    return reset_streak if profile.next_streak_date < today

    streak_rewarded?
  end

  private

  def reset_streak
    profile.update(streak_date: today, streak_count: 1)
    false
  end

  def streak_rewarded?
    return unless profile.next_streak_date == today
    new_streak_count = profile.streak_count + 1
    profile.update(streak_count: new_streak_count, streak_date: today)
    new_streak_count >= team.streak_duration ? reward_streak : false
  end

  def reward_streak
    Tip.create! \
      from_profile: team.app_profile,
      to_profile: profile,
      quantity: team.streak_reward,
      event_ts:,
      source: 'streak'
    true
  end

  def team
    @team ||= profile.team
  end

  def today
    @today ||= Time.use_zone(team.time_zone) { Time.zone.today }
  end
end
