# frozen_string_literal: true
class HintService < Base::Service
  include PointsHelper

  option :team

  def call
    return if team.hint_channel_rid.blank? || team.hint_frequency.never?
    post_random_hint
  end

  private

  def post_random_hint
    responder.call(team_rid: team.rid, team_config: team.config, mode: :hint, text: text)
    team.update!(hint_posted_at: Time.current)
  end

  def text
    ":bulb: *Hint*: #{hints.sample}"
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
      "Give #{App.singular_prefix} #{App.points_term} to a user by entering `@Alice++`",
      "Give multiple #{App.points_term} to a user by adding a number as in `@Alice++2`",
      "Specify a note when giving #{App.points_term} by adding it at the end of your message as in `@Alice++ thanks for the donuts!`",
      "Give #{App.points_term} to everyone in the current channel by entering `[@]channel++` (without the brackets)",
      "Give #{App.points_term} to everyone in a channel by entering `#some-channel++`",
      "Give #{App.points_term} to everyone in a user group by entering `#some-group++`",
      '"Be excellent to each other" - Wyld Stallyns',
      'Tell me `help` to see a detailed help menu',
      'Tell me `preferences` to open a personal preferences dialog',
      'Tell me `stats` or `me` to see your personal stats and `stats @username` to see the stats of another user',
      "Tell me `top` to see the top #{App.points_term} earners",
      "Tell me `top givers` to see the top #{App.points_term} givers",
      'Tell me `admin` to see a list of administrator settings',
      'Tell me `connect` to browse web-based profiles of yourself and your teammates as well as receive a weekly email report of your activity'
    ]

    if team.enable_levels?
      h += [
        "Tell me `levels` to see a chart of #{App.points_term} required to attain each level"
      ]
    end

    if team.enable_topics?
      h += [
        "Tell me `topics` to see a list of topics you can specify when giving #{App.points_term}"
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
      "Enter `/#{App.base_command}` by itself for a helpful dialog",
      "You can issue a command by messaging a keyword to me directly, by using my name `@#{App.bot_name}` followed by a keyword, or by using the command `/#{App.base_command}` followed by a keyword",
      "Give #{App.points_term} to the author of a message by clicking the three dots `...` on the right side of the message and selecting `User ++`"
    ]
    if team.enable_loot?
      h += [
        'Tell me `shop` to see a list of claimable rewards and `claim [item]` to claim one'
      ]

      h += team.rewards.active.map do |reward|
        next if reward.remaining.zero?
        <<~TEXT
          Claim the reward *#{reward.name}* for #{reward.price} #{App.points_term} by entering `claim #{reward.name}`
        TEXT
      end
    end

    h
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Layout/LineLength
end
