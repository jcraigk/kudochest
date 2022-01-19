# frozen_string_literal: true
class Slack::Modals::Preferences < Base::Service
  OPTIONS = %i[
    allow_dm
    announce_tip_sent
    announce_tip_received
    share_history
    weekly_report
  ].freeze

  option :team_rid
  option :profile_rid

  def call
    modal_block
  end

  private

  def modal_block
    {
      type: :modal,
      callback_id: :submit_prefs_modal,
      title: title,
      submit: submit,
      close: close,
      blocks: [checkboxes]
    }
  end

  def title
    {
      type: :plain_text,
      text: t('profiles.prefs_modal_title')
    }
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

  def checkboxes
    {
      type: 'section',
      text: prefs_text,
      accessory: {
        type: 'checkboxes',
        action_id: :prefs,
        initial_options:,
        options: prefs_options
      }
    }
  end

  def prefs_options
    OPTIONS.map { |opt| checkbox_for(opt) }
  end

  def prefs_text
    {
      type: 'plain_text',
      text: t('profiles.prefs_modal_info')
    }
  end

  def initial_options
    OPTIONS.each_with_object([]) do |opt, opts|
      next unless profile.send("#{opt}?")
      opts << checkbox_for(opt)
    end.compact
  end

  def checkbox_for(opt)
    {
      value: opt,
      text: {
        type: :plain_text,
        text: t("profiles.prefs_modal_#{opt}", bot: App.bot_name, points: App.points_term)
      }
    }
  end

  def profile
    @profile ||= Profile.find_with_team(team_rid, profile_rid)
  end
end
