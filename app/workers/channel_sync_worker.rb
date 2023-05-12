class ChannelSyncWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform(team_rid, new_channel_rid = nil)
    team = Team.find_by!(rid: team_rid)
    return unless team.active?
    ConstService.call(team.plat, 'ChannelSyncService').call(team:, new_channel_rid:)
  end
end
