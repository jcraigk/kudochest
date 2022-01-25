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
      **#{giving_title}:**
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

  def giving_title
    str = "Giving #{App.points_term.titleize}"
    str += " and #{App.jabs_term.titleize}" if team.enable_jabs?
    str
  end

  def discord_giving_points
    str = discord_point_inlines
    str += discord_jab_inlines if team.enable_jabs?
    return str unless team.enable_emoji?
    str += discord_point_emojis
    str += discord_jab_emojis if team.enable_jabs?
    str + discord_ditto
  end

  def giving_terms
    str = App.point_term
    str += "/#{App.jab_term}" if team.enable_jabs?
    str
  end

  def discord_ditto
    "\n  * React to #{giving_terms} message with #{team.ditto_emoj}" \
      " (#{team.ditto_emoji}) to duplicate it"
  end

  def discord_point_inlines
    "* Type `#{PROF_PREFIX}user++`, `#{PROF_PREFIX}role++`, " \
      "`#{CHAN_PREFIX}channel++`, or `#{CHAN_PREFIX}everyone++` " \
      'in a guild channel _(tip: append a number like `++2`)_'
  end

  def discord_jab_inlines
    "* Type `#{PROF_PREFIX}user--`, `#{PROF_PREFIX}role--`, " \
      "`#{CHAN_PREFIX}channel--`, or `#{CHAN_PREFIX}everyone--` " \
      'in a guild channel _(tip: append a number like `++2`)_'
  end

  def discord_point_emojis
    "\n  * Type `#{PROF_PREFIX}user`#{team.tip_emoj}, " \
      "`#{PROF_PREFIX}role`#{team.tip_emoj}, " \
      "`#{CHAN_PREFIX}channel`#{team.tip_emoj}, " \
      "or `#{CHAN_PREFIX}everyone`#{team.tip_emoj} in a guild channel " \
      "\n  * React with #{team.tip_emoj} (#{team.tip_emoji})"
  end

  def discord_jab_emojis
    "\n  * Type `#{PROF_PREFIX}user`#{team.jab_emoj}, " \
      "`#{PROF_PREFIX}role`#{team.jab_emoj}, " \
      "`#{CHAN_PREFIX}channel`#{team.jab_emoj}, " \
      "or `#{CHAN_PREFIX}everyone`#{team.jab_emoj} in a guild channel " \
      "\n  * React with #{team.tip_emoj} (#{team.tip_emoji})"
  end

  def slack_text
    <<~TEXT.chomp
      *#{giving_title}:*
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
    str = slack_point_inlines
    str += slack_jab_inlines if team.enable_jabs?
    str += slack_emojis if team.enable_emoji?
    "#{str}\n  * _User ++_ Action (\"...\" menu on a user message)"
  end

  def slack_point_inlines
    "* Type `/#{App.base_command}` by itself for assistance " \
      '_(tip: use Tab key to navigate input fields)_' \
      "\n  * Type `#{PROF_PREFIX}[user]++`, `#{PROF_PREFIX}[group]++`, " \
      "`#{CHAN_PREFIX}[channel]++`, `#{PROF_PREFIX}channel++`, " \
      "or `#{PROF_PREFIX}everyone++` _(tip: append a number like `++2`)_"
  end

  def slack_jab_inlines
    "\n  * Type `#{PROF_PREFIX}[user]--`, `#{PROF_PREFIX}[group]--`, " \
      "`#{CHAN_PREFIX}[channel]--`, `#{PROF_PREFIX}channel--`, " \
      "or `#{PROF_PREFIX}everyone--` _(tip: append a number like `--2`)_"
  end

  def slack_emojis
    str = slack_point_emojis
    str += slack_jab_emojis if team.enable_jabs?
    str += "\n  * React with #{team.tip_emoj} to give to the author of a message"
    str + "\n  * React to #{giving_terms} message with #{team.ditto_emoj} to duplicate it"
  end

  def slack_point_emojis
    "\n  * Type `#{PROF_PREFIX}[user]`#{team.tip_emoj}, " \
      "`#{PROF_PREFIX}[group]`#{team.tip_emoj}, " \
      "`#{CHAN_PREFIX}[channel]`#{team.tip_emoj}, " \
      "`#{PROF_PREFIX}channel`#{team.tip_emoj}, or " \
      "`#{PROF_PREFIX}everyone`#{team.tip_emoj}"
  end

  def slack_jab_emojis
    "\n  * Type `#{PROF_PREFIX}[user]`#{team.jab_emoj}, " \
      "`#{PROF_PREFIX}[group]`#{team.jab_emoj}, " \
      "`#{CHAN_PREFIX}[channel]`#{team.jab_emoj}, " \
      "`#{PROF_PREFIX}channel`#{team.jab_emoj}, or " \
      "`#{PROF_PREFIX}everyone`#{team.jab_emoj}"
  end
end
