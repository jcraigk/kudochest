class Slack::TeamSyncService < Base::TeamSyncService
  private

  def fetch_team_members
    cursor = nil
    members = []
    loop do
      data = team.slack_client.users_list(cursor:)
      members += data[:members]
      break if (cursor = data.dig(:response_metadata, :next_cursor)).blank?
    end
    members
  end

  def active?(member)
    !restricted?(member) && !member[:deleted] && !bot?(member)
  end

  def app_bot?(member)
    member[:profile][:api_app_id] == App.slack_app_id
  end

  def base_attributes(member)
    {
      team:,
      rid: member[:id]
    }
  end

  def syncable_attributes(member)
    {
      display_name: display_name(member),
      real_name: real_name(member),
      title: member[:profile][:title],
      bot_user: app_bot?(member),
      avatar_url: member[:profile][:image_512]
    }.compact
  end

  def display_name(member)
    member[:profile][:display_name_normalized].presence || real_name(member)
  end

  def real_name(member)
    member[:profile][:real_name_normalized]
  end

  def bot?(member)
    member[:is_bot] || member[:is_app_user] || member[:id] == 'USLACKBOT'
  end

  def restricted?(member)
    !!(member[:is_restricted] || member[:is_ultra_restricted])
  end

  def team
    @team ||= Team.find_by!(rid: team_rid)
  end
end
