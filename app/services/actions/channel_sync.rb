# frozen_string_literal: true
class Actions::ChannelSync < Actions::Base
  def call
    sync_channels
  end

  private

  def sync_channels
    ChannelSyncWorker.perform_async(params[:team_rid], new_channel_rid)
  end

  def new_channel_rid
    return unless params.dig(:event_params, :event, :type) == 'channel_created'
    params.dig(:event_params, :event, :channel, :id)
  end
end
