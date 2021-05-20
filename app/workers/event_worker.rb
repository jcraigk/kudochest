# frozen_string_literal: true
class EventWorker
  include Sidekiq::Worker
  sidekiq_options queue: :chat_events

  def perform(params)
    params['event'] = JSON[params['event']] if params['event'].present?
    params['team_config'] = OpenStruct.new(params['team_config']) if params['team_config'].present?

    EventService.call(params: params.deep_symbolize_keys)
  end
end
