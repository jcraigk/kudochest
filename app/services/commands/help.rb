# frozen_string_literal: true
class Commands::Help < Commands::Base
  def call
    OpenStruct.new(
      mode: :private,
      text: send("#{team.platform}_text")
    )
  end

  private

  def shop_keywords
    return unless team.enable_loot?
    <<~TEXT.chomp
      * `shop`  See a list of claimable rewards
        * `claim [item]`  Claim a shop item by name
    TEXT
  end

  def keyword_list
    <<~TEXT.chomp
      * `connect`  Connect your chat profile to your web account
        * `help`  You're looking at it!
        * `levels`  See a chart mapping #{App.points_term} to levels
        * `me`  See your current stats
        * `mute`  Disable unsolicited direct messages
        * `settings`  See app configuration (set by admin)
        * `stats #{PROF_PREFIX}user`  See another user's stats (minus private stuff)
        * `top`  See the leaderboard
        * `topics`  See all topics
        * `undo`  Revoke #{App.points_term} you just gave
        * `unmute`  Enable unsolicited direct messages
    TEXT
  end

  def discord_text
    <<~TEXT.chomp
      **Giving #{App.points_term.titleize}:**
        #{discord_giving_points}

      **Issuing commands:**
        * `#{App.discord_command} [keyword]`
        * `#{PROF_PREFIX}#{team.app_profile.display_name} [keyword]`

      **Command keywords:**
        #{keyword_list}
        #{shop_keywords}

      See <#{team.help_url}> for more info
    TEXT
  end

  # rubocop:disable Layout/LineLength
  def discord_giving_points
    str = "* Type `#{PROF_PREFIX}user++`, `#{PROF_PREFIX}role++`, `#{CHAN_PREFIX}channel++`, or `#{CHAN_PREFIX}everyone++` in a guild channel"
    return str unless team.enable_emoji?
    str += "\n  * Type `#{PROF_PREFIX}user`#{team.custom_emoj}, `#{PROF_PREFIX}role`#{team.custom_emoj}, `#{CHAN_PREFIX}channel`#{team.custom_emoj}, or `#{CHAN_PREFIX}everyone`#{team.custom_emoj} in a guild channel"
    str + "\n  * React with #{team.custom_emoj} (:#{App.discord_emoji}:)"
  end
  # rubocop:enable Layout/LineLength

  def slack_text
    <<~TEXT.chomp
      *Giving #{App.points_term}:*
        #{slack_giving_points}

      *Issuing commands:*
        * `/#{App.base_command} [keyword]`
        * `#{team.app_profile.link} [keyword]` where bot can hear
        * Direct message to #{team.app_profile.link}

      *Command keywords:*
        #{keyword_list}
        #{shop_keywords}

      See <#{team.help_url}|help on the web> for more info
    TEXT
  end

  # rubocop:disable Layout/LineLength
  def slack_giving_points
    str = "* `/#{App.base_command}` by itself for assistance _(tip: use Tab key)_"
    str += "\n  * Type `#{PROF_PREFIX}user++`, `#{PROF_PREFIX}group++`, `#{CHAN_PREFIX}channel++`, or `#{CHAN_PREFIX}everyone++` where bot can hear"
    if team.enable_emoji?
      str += "\n  * Type `#{PROF_PREFIX}user`#{team.custom_emoj}, `#{PROF_PREFIX}group`#{team.custom_emoj}, `#{CHAN_PREFIX}channel`#{team.custom_emoj}, or `#{CHAN_PREFIX}everyone`#{team.custom_emoj} where bot can hear"
      str += "\n  * React with #{team.custom_emoj} where bot can hear"
    end
    "#{str}\n  * _User ++_ Action (\"...\" menu on a user message)"
  end
  # rubocop:enable Layout/LineLength
end
