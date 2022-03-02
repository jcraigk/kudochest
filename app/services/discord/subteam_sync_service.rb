# frozen_string_literal: true
class Discord::SubteamSyncService < Base::SubteamSyncService
  private

  def profile_rids_for(role)
    @profile_rids ||= {}
    return @profile_rids[role] if @profile_rids[role].present?
    @profile_rids[role] =
      team.profiles.active.each_with_object([]) do |profile, rids|
        rids << profile.rid if role[:rid].in?(role_rids_for(profile))
      end.uniq
  end

  def remote_subteams
    @remote_subteams ||= raw_subteams.reject { |role| role[:managed] || role[:name] == '@everyone' }
  end

  def app_subteam_rid
    @app_subteam_rid ||=
      raw_subteams.select { |role| role[:managed] }
                  .find { |role| role[:name] == ENV['DISCORD_APP_USERNAME'] || App.app_name }
                  &.dig(:id)
  end

  def raw_subteams
    @raw_subteams ||= JSON.parse \
      Discordrb::API::Server.roles(App.discord_token, team.rid),
      symbolize_names: true
  end

  def syncable_attributes(role)
    { name: role[:name] }
  end

  def role_rids_for(profile)
    JSON[
      Discordrb::API::Server.resolve_member(App.discord_token, team.rid, profile.rid)
    ]['roles'].map(&:to_s)
  end
end
