# frozen_string_literal: true
class Slack::ModalView < Base::Service
  option :team_rid

  def call
    modal_block
  end

  private

  # rubocop:disable Metrics/MethodLength
  def modal_block
    {
      type: :modal,
      callback_id: :modal_submit,
      title: {
        type: :plain_text,
        text: "Give #{App.points_term.titleize}"
      },
      submit: {
        type: :plain_text,
        text: 'Submit'
      },
      close: {
        type: :plain_text,
        text: 'Cancel'
      },
      blocks: [rid_multiselect, quantity_select, topic_select, note_input].compact
    }
  end

  def rid_multiselect
    {
      type: :input,
      label: {
        type: :plain_text,
        text: 'Recipients'
      },
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
    return unless team_config.enable_topics && team_config.topics.any?

    basic_topic_select.tap do |block|
      next if team_config.require_topic
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
      next if team_config.require_topic
      options.unshift(no_topic_option)
    end
  end

  def active_topic_select_options
    team_config.topics.map do |topic|
      {
        text: {
          type: :plain_text,
          text: topic.name
        },
        value: topic.id
      }
    end
  end

  def quantity_options
    (fractional_quantity_options + (1..team_config.max_points_per_tip).to_a).compact
  end

  def fractional_quantity_options
    case team_config.tip_increment
    when 0.01 then [0.01, 0.05, 0.1, 0.25, 0.5, 0.75]
    when 0.1 then [0.1, 0.5]
    when 0.25 then [0.25, 0.5, 0.75]
    when 0.5 then [0.5]
    else []
    end
  end

  def note_input
    return if team_config.tip_notes == 'disabled'

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
        min_length: team_config.tip_notes == 'required' ? 5 : 0,
        max_length: App.max_note_length
      }
    }
  end
  # rubocop:enable Metrics/MethodLength

  def team_config
    @team_config ||= Cache::TeamConfig.call(team_rid)
  end
end
