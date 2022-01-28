# frozen_string_literal: true
class HintService < Base::Service
  include ActionView::Helpers::AssetUrlHelper
  include PointsHelper
  include Webpacker::Helper

  option :team

  def call
    return if team.hint_channel_rid.blank? || team.hint_frequency.never?
    post_random_hint
  end

  private

  def post_random_hint
    responder.call \
      team_rid: team.rid,
      config: team.config,
      mode: :hint,
      text:,
      channel_rid: team.hint_channel_rid
    team.update!(hint_posted_at: Time.current)
  end

  def hint_idx
    @hint_idx ||= rand(hints.size)
  end

  def text
    team.platform.slack? ? blocks : raw_text
  end

  def raw_text
    <<~TEXT
      :bulb: *Usage Hint ##{hint_idx + 1}*\n#{hints[hint_idx]}\nEnter `/kudos help` for more help.
    TEXT
  end

  def blocks # rubocop:disable Metrics/MethodLength
    {
      blocks: [
        {
          type: :divider
        },
        {
          type: :section,
          text: {
            type: :mrkdwn,
            text:
              <<~TEXT
                :bulb: *Usage Hint ##{hint_idx + 1}*\n\n#{hints[hint_idx]}\n\nEnter `/kudos help` for more help.
              TEXT
          },
          accessory: {
            type: :image,
            image_url: "#{App.asset_host}#{logo_image_path}",
            alt_text: "#{App.app_name} Logo"
          }
        },
        {
          type: :divider
        }
      ]
    }
  end

  def logo_image_path
    asset_pack_path('media/images/logos/app-reverse-144.png')
  rescue Webpacker::Manifest::MissingEntryError
    nil
  end

  def responder
    @responder ||= "#{team.platform.titleize}::PostService".constantize
  end

  def hints
    team.platform.slack? ? shared_hints + slack_hints : shared_hints
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Layout/LineLength
  def shared_hints
    h = [
      "Give #{App.point_singular_prefix} #{App.point_term} to a user by entering `@Alice++`",
      "Give multiple #{App.points_term} to a user by adding a number as in `@Alice++2`",
      "Specify a note when giving #{App.points_term} by adding it at the end of your message as in `@Alice++ thanks for the donuts!`",
      "Give #{App.points_term} to everyone in the current channel by entering `[@]channel++` (without the brackets)",
      "Give #{App.points_term} to everyone in a channel by entering `#some-channel++`",
      "Give #{App.points_term} to everyone in a user group by entering `#some-group++`",
      '"Be excellent to each other" - Wyld Stallyns',
      "Use the `help` command to see a detailed help menu. #{command_blerb}",
      "Use the `preferences` command to open a personal preferences dialog. #{command_blerb}",
      "Use the `stats` or `me` command to see your personal stats and `stats @username` to see the stats of another user. #{command_blerb}",
      "Use the `top` command to see the top #{App.points_term} earners. #{command_blerb}",
      "Use the `top givers` command to see the top #{App.points_term} givers. #{command_blerb}",
      "Use the `admin` command to see a list of administrator settings. #{command_blerb}",
      "Use the `connect` command to browse web-based profiles of yourself and your teammates as well as receive a weekly email report of your activity. #{command_blerb}"
    ]

    if team.enable_levels?
      h += [
        "Use the `levels` command to see a chart of #{App.points_term} required to attain each level. #{command_blerb}"
      ]
    end

    if team.enable_topics?
      h += [
        "Use the `topics` command to see a list of topics you can specify when giving #{App.points_term}. #{command_blerb}"
      ]
      h += team.topics.map do |topic|
        <<~TEXT
          Give #{App.points_term} for the topic *#{topic.name}* by using the :#{topic.emoji}: (`:#{topic.emoji}:`) emoji or `#{topic.keyword}` keyword
        TEXT
      end
    end

    if team.enable_emoji?
      h += [
        "Give #{App.points_term} to the author of a message by reacting with #{team.tip_emoj} (`#{team.tip_emoj}`)",
        "Give additional #{App.points_term} to a recipient by reacting with #{team.ditto_emoj} (`#{team.ditto_emoj}`)",
        "Give #{points_format(team.emoji_quantity, label: true)} to a user with inline emoji by entering `@Alice #{team.tip_emoj}`"
      ]
    end

    h
  end

  def slack_hints # rubocop:disable Metrics/MethodLength
    h = [
      "Enter `/#{App.base_command}` by itself for a helpful dialog. #{command_blerb}",
      "Give #{App.points_term} to the author of a message by clicking the three dots `...` on the right side of the message and selecting `User ++`"
    ]
    if team.enable_loot?
      h += [
        "Use the `shop` command to display claimable rewards and `claim [item]` to claim one. #{command_blerb}"
      ]

      h += team.rewards.active.map do |reward|
        next if reward.remaining.zero?
        <<~TEXT
          Claim the reward *#{reward.name}* for #{reward.price} #{App.points_term} by entering `claim #{reward.name}`. #{command_blerb}
        TEXT
      end
    end

    h
  end

  def command_blerb
    "You can issue a command by using the `/#{App.base_command}` command, by mentioning #{team.app_profile.link} in a public channel, or by sending a direct message to the #{App.app_name} app."
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Layout/LineLength
end
