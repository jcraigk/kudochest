# frozen_string_literal: true
class EventWorker
  include Sidekiq::Worker
  sidekiq_options queue: :chat_events

  def perform(params)
    # TODO: Clean up this deserialization
    params['event'] = JSON[params['event']] if params['event'].present?
    params['team_config'] = TeamConfig.new(params['team_config'])
    params['team_config']['topics'] = params['team_config']['topics'].map { |t| TopicData.new(t) }
    EventService.call(params: params.deep_symbolize_keys)
  end
end
