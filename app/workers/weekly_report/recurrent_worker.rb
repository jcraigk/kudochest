class WeeklyReport::RecurrentWorker
  include Sidekiq::Worker

  def perform
    run_team_report_workers
    run_profile_report_workers
  end

  private

  def run_team_report_workers
    Team.active
        .where(weekly_report: true)
        .where('created_at < ?', 1.week.ago)
        .find_each do |team|
      WeeklyReport::TeamWorker.perform_async(team.id)
    end
  end

  def run_profile_report_workers
    Profile.where(weekly_report: true).find_each do |profile|
      next unless profile.active? && profile.team.active?
      WeeklyReport::ProfileWorker.perform_async(profile.id)
    end
  end
end
