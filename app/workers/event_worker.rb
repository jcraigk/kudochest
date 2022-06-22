# frozen_string_literal: true
class EventWorker
  include Sidekiq::Worker

  def perform(params)
    EventService.call(params: JSON.parse(params, symbolize_names: true))
  end
end
