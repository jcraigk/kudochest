# frozen_string_literal: true
class EventWorker
  include Sidekiq::Worker
  sidekiq_options queue: :chat_events

  def perform(params)
    params['event'] = JSON[params['event']] if params['event'].present?
    params['team_config'] = TeamConfig.new(params['team_config'])
    EventService.call(params: params.deep_symbolize_keys)
  end
end
