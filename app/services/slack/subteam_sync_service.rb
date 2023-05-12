class Slack::SubteamSyncService < Base::SubteamSyncService
  private

  def profile_rids_for(subteam)
    remote_subteams.find { |remote| remote.id == subteam.rid }&.users&.uniq
  end

  def remote_subteams
    @remote_subteams ||= team.slack_client.usergroups_list(
      include_count: false,
      include_disabled: false,
      include_users: true
    )[:usergroups]
  end

  def syncable_attributes(remote_subteam)
    {
      name: remote_subteam[:name],
      description: remote_subteam[:description],
      handle: remote_subteam[:handle]
    }
  end

  # Slack does not create a subteam for bots
  def app_subteam_rid
    nil
  end
end
