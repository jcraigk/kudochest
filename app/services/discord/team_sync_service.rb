class Discord::TeamSyncService < Base::TeamSyncService
  private

  def fetch_team_members
    JSON.parse(discord_member_response, symbolize_names: true)
  end

  def discord_member_response
    Discordrb::API::Server.resolve_members(App.discord_token, team.rid, 1_000)
  end

  def active?(member)
    !bot?(member)
  end

  def app_bot?(member)
    bot?(member) && member[:username] == ENV.fetch('DISCORD_APP_USERNAME', App.app_name)
  end

  def bot?(member)
    member[:bot] == true
  end

  def base_attributes(member)
    {
      team:,
      rid: member[:id]
    }
  end

  def syncable_attributes(member)
    {
      display_name: member[:username],
      real_name: member[:username],
      bot_user: app_bot?(member),
      avatar_url: avatar_url(member)
    }
  end

  def default_avatar_url
    "https://#{ENV.fetch('WEB_DOMAIN', 'localhost')}/assets/static/profile-default-256.webp"
  end

  def avatar_url(member)
    return default_avatar_url if member[:avatar].blank?
    "#{App.discord_cdn_base}/avatars/#{member[:id]}/#{member[:avatar]}.png?size=256"
  end
end
