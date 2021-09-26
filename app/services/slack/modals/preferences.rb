# frozen_string_literal: true
class Slack::Modals::Preferences < Base::Service
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
      blocks: [prefs_checkboxes]
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

  def prefs_checkboxes
    {
      type: 'section',
      text: prefs_text,
      accessory: {
        type: 'checkboxes',
        action_id: :prefs,
        initial_options: initial_options,
        options: prefs_options
      }
    }
  end

  def prefs_options
    [
      allow_dm_checkbox,
      weekly_report_checkbox
    ].compact
  end

  def prefs_text
    {
      type: 'plain_text',
      text: t('profiles.prefs_modal_info')
    }
  end

  def initial_options
    [].tap do |opts|
      opts << allow_dm_checkbox if profile.allow_dm?
      opts << weekly_report_checkbox if profile.weekly_report?
    end
  end

  def allow_dm_checkbox
    {
      value: :allow_dm,
      text: {
        type: :plain_text,
        text: t('profiles.prefs_modal_allow_dm', bot: App.bot_name)
      }
    }
  end

  def weekly_report_checkbox
    i18n_suffix = profile.user.blank? ? '_must_connect' : nil
    {
      value: :weekly_report,
      text: {
        type: :plain_text,
        text: t("profiles.prefs_modal_weekly_report#{i18n_suffix}")
      }
    }
  end

  def profile
    @profile ||= Profile.find_with_team(team_rid, profile_rid)
  end
end
