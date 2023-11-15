class EventService < Base::Service
  option :params

  def call
    return post_success_message if respond_in_chat?
    delete_slack_ack_message if slack_fast_acked?
  rescue StandardError => e
    Rails.logger.error(e) if reportable?(e)
    post_error_message(e)
  end

  private

  def delete_slack_ack_message
    Slack::Web::Client
      .new(token: params[:config][:api_key])
      .chat_delete(channel: params[:replace_channel_rid], ts: params[:replace_ts])
  end

  def slack_fast_acked?
    params[:platform] == 'slack' &&
      params.dig(:config, :enable_fast_ack?) &&
      params[:replace_channel_rid].present? &&
      params[:replace_ts].present?
  end

  def responder
    @responder ||= ConstService.call(params[:platform], 'PostService')
  end

  def post_success_message
    responder.call(**params.merge(result.to_h))
  end

  def result
    @result ||= action_service.call(**params)
  end

  def action_service
    const = "Actions::#{params[:action].titleize.tr(' ', '')}"
    return unless Object.const_defined?(const)
    const.constantize
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
    responder.call(**params.merge(mode: :error, text:))
  end

  def reportable?(exception)
    !exception.is_a?(ActiveRecord::RecordNotUnique) &&
      !exception.is_a?(ActiveRecord::RecordInvalid)
  end

  def error_text(exception)
    case exception.class.name
    when 'ChatFeedback' then exception.message
    when 'ActiveRecord::RecordNotUnique' then 'Duplicate request ignored'
    when 'ActiveRecord::RecordInvalid' then validation_message(exception)
    else I18n.t('slack.generic_error')
    end
  end

  def validation_message(exception)
    exception.message.gsub('Validation failed: ', '')
  end

  def log_exception(exception)
    Rails.logger.info("#{exception.message}\n#{exception.backtrace.join("\n")}")
  end
end
