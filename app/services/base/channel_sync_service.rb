# frozen_string_literal: true
class Base::ChannelSyncService < Base::Service
  option :team
  option :new_channel_rid

  def call
    sync_active_channels
    destroy_old_channels
  end

  private

  def sync_active_channels
    remote_channels.each do |remote_channel|
      base_attrs = base_attributes(remote_channel)
      sync_attrs = syncable_attributes(remote_channel)

      if (channel = Channel.find_by(base_attrs))
        channel.update(sync_attrs)
      else
        Channel.create!(base_attrs.merge(sync_attrs))
      end
    end
  end

  def old_channel_rids
    @old_channel_rids ||= team.channels.pluck(:rid) - remote_channels.pluck(:id)
  end

  def destroy_old_channels
    team.channels.where(rid: old_channel_rids).destroy_all
    team.update!(log_channel_rid: nil) if team.log_channel_rid.in?(old_channel_rids)
  end

  def remote_channels
    @remote_channels ||= fetch_remote_channels
  end
end
