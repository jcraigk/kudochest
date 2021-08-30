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
        * `stats #{PROF_PREFIX}user`  See another user's stats
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

      :question: <#{team.help_url}> :bug: <#{App.bug_url}>
    TEXT
  end

  # rubocop:disable Layout/LineLength
  def discord_giving_points
    str = "* Type `#{PROF_PREFIX}user++`, `#{PROF_PREFIX}role++`, `#{CHAN_PREFIX}channel++`, or `#{CHAN_PREFIX}everyone++` in a guild channel"
    return str unless team.enable_emoji?
    str += "\n  * Type `#{PROF_PREFIX}user`#{team.tip_emoj}, `#{PROF_PREFIX}role`#{team.tip_emoj}, `#{CHAN_PREFIX}channel`#{team.tip_emoj}, or `#{CHAN_PREFIX}everyone`#{team.tip_emoj} in a guild channel"
    str + "\n  * React with #{team.tip_emoj} (#{team.tip_emoji})"
    str + "\n  * React with #{team.ditto_emoj} (#{team.ditto_emoji})"
  end
  # rubocop:enable Layout/LineLength

  def slack_text
    <<~TEXT.chomp
      *Giving #{App.points_term}:*
        #{slack_giving_points}

      *Issuing commands:*
        * Type `/#{App.base_command} [keyword]` anywhere
        * Type `#{team.app_profile.link} [keyword]` where bot is present
        * Send direct message to #{team.app_profile.link}

      *Command keywords:*
        #{keyword_list}
        #{shop_keywords}

      :question: <#{team.help_url}|Get more help> :bug: <#{App.bug_url}|Submit a bug>
    TEXT
  end

  def slack_giving_points
    str =
      "* Type `/#{App.base_command}` by itself for assistance " \
      '_(tip: use Tab key to navigate input fields)_' \
      "* Type `#{PROF_PREFIX}[user]++`, `#{PROF_PREFIX}[group]++`, " \
      "`#{CHAN_PREFIX}[channel]++`, `#{PROF_PREFIX}channel++`, " \
      "or `#{PROF_PREFIX}everyone++` where bot can hear"
    str += slack_emoji_options if team.enable_emoji?
    "#{str}\n  * _User ++_ Action (\"...\" menu on a user message)"
  end

  def slack_emoji_options
    str =
      "\n  * Type `#{PROF_PREFIX}[user]`#{team.tip_emoj}, " \
      "`#{PROF_PREFIX}[group]`#{team.tip_emoj}, " \
      "`#{CHAN_PREFIX}[channel]`#{team.tip_emoj}, " \
      "`#{PROF_PREFIX}channel`#{team.tip_emoj}, or " \
      "`#{PROF_PREFIX}everyone`#{team.tip_emoj} where bot can hear"
    str += "\n  * React with #{team.tip_emoj} to give to author of message"
    str + "\n  * React with #{team.ditto_emoj} to give more to recipient(s)"
  end
end
