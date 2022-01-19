# frozen_string_literal: true
class Slack::ChannelService < Base::ChannelService
  def call
    super
    join_new_channel
  end

  private

  def join_new_channel
    return unless new_channel_rid.present? && team.join_channels?
    Slack::ChannelJoinService.call(team:, channel_rid: new_channel_rid)
  end

  def fetch_remote_channels
    cursor = nil
    channels = []
    loop do
      data = page_of_remote_channels(cursor)
      channels += data[:channels]
      break if (cursor = data.dig(:response_metadata, :next_cursor)).blank?
    end
    channels
  end

  def page_of_remote_channels(cursor)
    team.slack_client.conversations_list \
      types: 'public_channel',
      exclude_archived: true,
      cursor:
  end

  def base_attributes(channel)
    {
      team: team,
      rid: channel[:id]
    }
  end

  def syncable_attributes(channel)
    {
      name: channel[:name],
      shared: channel[:is_shared]
    }.compact
  end
end
