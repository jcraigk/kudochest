# frozen_string_literal: true
class Slack::Modals::Tip < Base::Service
  MAX_QUANTITY_OPTIONS = 99

  option :team_rid

  def call
    modal_block
  end

  private

  def modal_block
    {
      type: :modal,
      callback_id: :submit_tip_modal,
      title:,
      submit:,
      close:,
      blocks: [quantity_select, rid_multiselect, topic_select, note_input].compact
    }
  end

  def title
    {
      type: :plain_text,
      text: raw_title
    }
  end

  def raw_title
    str = "Give #{App.points_term.titleize}"
    str += " or #{App.jabs_term.titleize}" if config[:enable_jabs]
    str
  end

  def close
    {
      type: :plain_text,
      text: 'Cancel'
    }
  end

  def submit
    {
      type: :plain_text,
      text: 'Submit'
    }
  end

  # rubocop:disable Metrics/MethodLength
  def rid_multiselect
    {
      type: :input,
      label: {
        type: :plain_text,
        text: 'Recipients'
      },
      optional: false,
      element: {
        type: :multi_external_select,
        action_id: :rids,
        placeholder: {
          type: :plain_text,
          text: 'Users, groups, or channels'
        }
      }
    }
  end

  def quantity_select
    {
      type: :input,
      label: {
        type: :plain_text,
        text: 'Quantity'
      },
      optional: false,
      element: {
        type: :static_select,
        action_id: :quantity,
        initial_option: {
          text: {
            type: :plain_text,
            text: '1'
          },
          value: '1'
        },
        options: quantity_options.map do |quantity|
          {
            text: {
              type: :plain_text,
              text: quantity.to_s
            },
            value: quantity.to_s
          }
        end
      }
    }
  end

  def topic_select
    return unless config[:enable_topics] && config[:topics].any?

    basic_topic_select.tap do |block|
      next if config[:require_topic]
      block[:element][:initial_option] = no_topic_option
    end
  end

  def basic_topic_select
    {
      type: :input,
      label: {
        type: :plain_text,
        text: 'Topic'
      },
      element: {
        type: :static_select,
        action_id: :topic_id,
        placeholder: {
          type: :plain_text,
          text: 'Select a topic'
        },
        options: topic_select_options
      }
    }
  end

  def no_topic_option
    {
      text: {
        type: :plain_text,
        text: 'No topic'
      },
      value: '0'
    }
  end

  def topic_select_options
    active_topic_select_options.tap do |options|
      next if config[:require_topic]
      options.unshift(no_topic_option)
    end
  end

  def active_topic_select_options
    config[:topics].map do |topic|
      {
        text: {
          type: :plain_text,
          text: topic[:name]
        },
        value: topic[:id]
      }
    end
  end

  def quantity_options
    return base_quantities unless config[:enable_jabs]
    base_quantities.reverse.map { |q| 0 - q } + base_quantities
  end

  # Slack allows limited options in dropdowns
  def base_quantities
    divisor = config[:enable_jabs] ? 2.0 : 1.0 # Need to fit negative numbers too
    all_quantities.take((MAX_QUANTITY_OPTIONS.to_f / divisor).floor)
  end

  def all_quantities
    (
      fractional_quantity_options +
      (1..config[:max_points_per_tip]).to_a
    ).compact
  end

  def fractional_quantity_options
    case config[:tip_increment]
    when 0.01 then [0.01, 0.05, 0.1, 0.25, 0.5, 0.75]
    when 0.1 then [0.1, 0.5]
    when 0.25 then [0.25, 0.5, 0.75]
    when 0.5 then [0.5]
    else []
    end
  end

  def note_input
    return if config[:tip_notes] == 'disabled'

    {
      type: :input,
      optional: true,
      label: {
        type: :plain_text,
        text: 'Note'
      },
      element: {
        type: :plain_text_input,
        action_id: :note,
        min_length: config[:tip_notes] == 'required' ? 5 : 0,
        max_length: App.max_note_length
      }
    }
  end
  # rubocop:enable Metrics/MethodLength

  def config
    @config ||= Cache::TeamConfig.call(:slack, team_rid)
  end
end
