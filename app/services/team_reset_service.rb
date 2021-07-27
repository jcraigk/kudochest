# frozen_string_literal: true
class TeamResetService < Base::Service
  option :team

  def call
    Team.transaction do
      reset_all_stats
      TokenDispersalService.call(team: team, notify: false)
    end
  end

  private

  def reset_all_stats
    team.profiles.find_each do |profile|
      destroy_tips(profile)
      reset_profile_stats(profile)
      notify_user(profile, t('teams.stats_reset'))
    end
    team.update!(points_sent: 0)
  end

  def reset_profile_stats(profile)
    profile.update!(
      points_received: 0,
      points_sent: 0,
      points_claimed: 0,
      tokens_accrued: 0,
      tokens_forfeited: 0,
      last_tip_received_at: nil,
      last_tip_sent_at: nil
    )
  end

  def destroy_tips(profile)
    Tip.where(to_profile: profile)
       .or(Tip.where(from_profile: profile))
       .delete_all
  end

  def notify_user(profile, text)
    return unless profile.allow_unprompted_dm?
    "#{team.plat}::PostService".constantize.call(
      team_rid: team.rid,
      profile_rid: profile.rid,
      mode: :direct,
      text: text,
      team_config: team.config
    )
  end
end
