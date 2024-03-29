class Discord::ChannelSyncService < Base::ChannelSyncService
  def fetch_remote_channels
    JSON.parse(discord_response, symbolize_names: true)
        .select { |d| d[:type].zero? } # Text channels only
  end

  def base_attributes(channel)
    {
      team:,
      rid: channel[:id]
    }
  end

  def syncable_attributes(channel)
    { name: channel[:name] }
  end

  def discord_response
    Discordrb::API::Server.channels(App.discord_token, team.rid)
  end
end
