# frozen_string_literal: true
class Slack::SubteamService < Base::SubteamService
  private

  def profile_rids_for(subteam)
    remote_subteams.find { |sub| sub.id == subteam.rid }.users
  end

  def remote_subteams
    @remote_subteams ||= team.slack_client.usergroups_list(
      include_count: false,
      include_disabled: false,
      include_users: true
    )[:usergroups].map { |data| OpenStruct.new(data) }
  end

  def syncable_attributes(remote_subteam)
    {
      name: remote_subteam.name,
      description: remote_subteam.description,
      handle: remote_subteam.handle
    }
  end

  # Slack does not create a subteam for bots
  def app_subteam_rid
    nil
  end
end
