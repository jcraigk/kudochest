# frozen_string_literal: true
class Actions::SubmitTipModal < Actions::Base
  def call
    return if mentions.blank?
    create_tips_and_respond
  end

  private

  def create_tips_and_respond
    TipMentionService.call \
      profile:,
      mentions:,
      note:,
      source: 'modal',
      event_ts:,
      channel_rid: params[:channel_rid],
      channel_name: params[:channel_name]
  end

  def event_ts
    params[:trigger_id].split('.').take(2).join('.')
  end

  def mentions
    submission
      .find { |_k, v| v[:rids] }
      .second[:rids][:selected_options]&.map do |option|
        val = option[:value]
        Mention.new \
          rid: "#{prefix(val)}#{val}",
          topic_id:,
          quantity: BigDecimal(quantity.presence || 0)
      end || []
  end

  def prefix(val)
    return if val == 'channel'

    case val.first
    when 'U' then PROF_PREFIX
    when 'C' then CHAN_PREFIX
    when 'S' then SUBTEAM_PREFIX[:slack]
    end
  end

  def note
    @note ||= submission.find { |_k, v| v[:note].present? }&.second&.dig(:note, :value)
  end

  def quantity
    @quantity ||=
      BigDecimal \
        submission.find { |_k, v| v[:quantity].present? }
                  &.second
                  &.dig(:quantity, :selected_option, :value)
                  .presence || 0
  end

  def topic_id
    @topic_id ||=
      submission.find { |_k, v| v[:topic_id].present? }
                &.second
                &.dig(:topic_id, :selected_option, :value)
  end

  def submission
    @submission ||= params[:view][:state][:values]
  end
end
