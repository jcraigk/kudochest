# frozen_string_literal: true
class EventService < Base::Service
  option :params

  def call
    return post_success_message if respond_in_chat?
    delete_slack_ack_message if slack_fast_acked?
  rescue StandardError => e
    Honeybadger.notify(e) if defined?(Honeybadger) && reportable?(e)
    post_error_message(e)
  end

  private

  def delete_slack_ack_message
    Slack::Web::Client
      .new(token: params[:team_config][:api_key])
      .chat_delete(channel: params[:replace_channel_rid], ts: params[:replace_ts])
  end

  def slack_fast_acked?
    params[:platform] == 'slack' &&
      params.dig(:team_config, :enable_fast_ack?) &&
      params[:replace_channel_rid].present? &&
      params[:replace_ts].present?
  end

  def responder
    @responder ||= "#{params[:platform].titleize}::PostService".constantize
  end

  def post_success_message
    responder.call(params.merge(result.to_h))
  end

  def result
    @result ||= "Actions::#{params[:action].titleize.tr(' ', '')}".constantize.call(params)
  end

  def respond_in_chat?
    result.try(:mode).present? && params[:response_mode] != :silent
  end

  def post_error_message(exception)
    log_exception(exception) if Rails.env.development?
    post_chat_error(exception)
  end

  def post_chat_error(exception)
    return if params[:channel_rid].blank? && params[:replace_channel_rid].blank?
    text = ":#{App.error_emoji}: #{error_text(exception)}"
    responder.call(params.merge(mode: :error, text: text))
  end

  def reportable?(exception)
    !exception.is_a?(ActiveRecord::RecordNotUnique) &&
      !exception.is_a?(ActiveRecord::RecordInvalid)
  end

  def error_text(exception)
    return 'Duplicate request ignored' if exception.is_a?(ActiveRecord::RecordNotUnique)
    return shortened_message(exception) if exception.is_a?(ActiveRecord::RecordInvalid)
    I18n.t('slack.generic_error')
  end

  def shortened_message(exception)
    exception.message.gsub(/Validation failed: /, '')
  end

  def log_exception(exception)
    Rails.logger.info("#{exception.message}\n#{exception.backtrace.join("\n")}")
  end
end
