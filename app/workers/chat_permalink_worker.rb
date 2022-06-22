# frozen_string_literal: true
class ChatPermalinkWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  SOURCES = %w[inline point_reaction jab_reaction ditto_reaction topic_reaction reply].freeze

  attr_reader :tip_id, :channel, :message_ts

  def perform(tip_id, channel, message_ts)
    @tip_id = tip_id
    @channel = channel
    @message_ts = message_ts

    return unless tip.source.in?(SOURCES)

    tip.update!(chat_permalink:) if chat_permalink.present?
  end

  private

  def chat_permalink
    @chat_permalink ||= tip.team.slack_client.chat_getPermalink(channel:, message_ts:).permalink
  rescue Slack::Web::Api::Errors::ChannelNotFound, Slack::Web::Api::Errors::MessageNotFound
    nil
  end

  def tip
    @tip ||= Tip.includes(from_profile: :team).find(tip_id)
  end
end
