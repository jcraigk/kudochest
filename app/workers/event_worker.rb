# frozen_string_literal: true
class EventWorker
  include Sidekiq::Worker
  sidekiq_options queue: :chat_events

  def perform(params)
    params.deep_symbolize_keys!
    params[:matches] = params[:matches].map { |m| ScanMatch.new(m) }
    EventService.call(params:)
  end
end
