# frozen_string_literal: true
class Commands::Help < Commands::Base
  def call
    ChatResponse.new(mode: :private, text: send("#{team.platform}_text"))
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
    str = "* `admin`  See app configuration\n"
    str += "  * `connect`  Connect your chat profile to your web account\n"
    str += "  * `help`  You're looking at it!\n"
    str += "  * `levels`  See a chart mapping #{App.points_term} to levels\n" if team.enable_levels?
    str += "  * `me`  See your current stats\n"
    str += "  * `preferences`  Update your preferences\n"
    str += "  * `stats #{PROF_PREFIX}user`  See another user's stats\n"
    str += "  * `top`  See the leaderboard\n"
    str += "  * `topics`  See all topics\n" if team.enable_topics?
    str + "  * `undo`  Revoke #{App.points_term} you just gave"
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

      :question: <#{team.help_url}> :bug: <#{App.issues_url}>
    TEXT
  end

  def discord_giving_points # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    str =
      "* Type `#{PROF_PREFIX}user++`, `#{PROF_PREFIX}role++`, " \
      "`#{CHAN_PREFIX}channel++`, or `#{CHAN_PREFIX}everyone++` " \
      'in a guild channel'
    return str unless team.enable_emoji?
    str +
      "\n  * Type `#{PROF_PREFIX}user`#{team.tip_emoj}, " \
      "`#{PROF_PREFIX}role`#{team.tip_emoj}, " \
      "`#{CHAN_PREFIX}channel`#{team.tip_emoj}, " \
      "or `#{CHAN_PREFIX}everyone`#{team.tip_emoj} in a guild channel " \
      "\n  * React with #{team.tip_emoj} (#{team.tip_emoji})" \
      "\n  * React with #{team.ditto_emoj} (#{team.ditto_emoji})"
  end

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

      :question: <#{team.help_url}|More help> :bug: <#{App.issues_url}|Submit bugs> :bulb: <#{App.issues_url}|Feature ideas>
    TEXT
  end

  def slack_giving_points
    str =
      "* Type `/#{App.base_command}` by itself for assistance " \
      '_(tip: use Tab key to navigate input fields)_' \
      "\n  * Type `#{PROF_PREFIX}[user]++`, `#{PROF_PREFIX}[group]++`, " \
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
