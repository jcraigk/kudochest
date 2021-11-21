# frozen_string_literal: true
class EventWorker
  include Sidekiq::Worker
  sidekiq_options queue: :chat_events

  def perform(params)
    params['event'] = JSON[params['event']] if params['event'].present?
    EventService.call(params: params.deep_symbolize_keys)
  end
end
