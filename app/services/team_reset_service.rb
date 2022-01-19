# frozen_string_literal: true
class TeamResetService < Base::Service
  option :team

  def call
    Team.transaction do
      reset_all_stats
      TokenDispersalService.call(team:, notify: false)
    end
  end

  private

  def reset_all_stats
    team.profiles.find_each do |profile|
      destroy_tips(profile)
      reset_profile_stats(profile)
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
end
