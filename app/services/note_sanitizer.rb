class NoteSanitizer < Base::Service
  option :platform
  option :team_rid
  option :text

  def call
    return if text.blank?

    sanitized_text
  end

  private

  def sanitized_text
    replace_channel_mentions
    replace_subteam_mentions
    replace_user_mentions
    replace_urls
    replace_special_chars

    text
  end

  # <!subteam^RID> => "@subteam-handle"
  def replace_subteam_mentions
    @text = text.gsub(SUBTEAM_REGEX[platform]) do
      subteam_reference(Regexp.last_match[1])
    end
  end

  # <@UA89HL> => "@user-display-name"
  # <@UA89HL|user-display-name> => "@user-display-name"
  def replace_user_mentions
    @text = text.gsub(PROFILE_REGEX[platform]) do
      if Regexp.last_match[3].present?
        "#{PROF_PREFIX}#{Regexp.last_match[3]}"
      else
        profile_reference(Regexp.last_match[1])
      end
    end
  end

  # <#C024BE7LR> => "#channel-name"
  # <#C024BE7LR|channel-name> => "#channel-name"
  def replace_channel_mentions
    @text = text.gsub(CHANNEL_REGEX[platform]) do
      if Regexp.last_match[3].present?
        "#{CHAN_PREFIX}#{Regexp.last_match[3]}"
      else
        channel_reference(Regexp.last_match[1])
      end
    end
  end

  # <http://google.com|google.com> => "google.com"
  def replace_urls
    @text = text.gsub(/<(?:http|https)[^|>]+\|([^>]+)>/) do
      Regexp.last_match[1]
    end
  end

  def replace_special_chars
    @text = text.gsub('&lt;', '<')
    @text = text.gsub('&gt;', '>')
    @text = text.gsub('&amp;', '&')
    @text = text.tr('*', '').strip
  end

  def profile_reference(rid)
    return unless (profile = Profile.find_with_team(team_rid, rid))
    "#{PROF_PREFIX}#{profile.display_name}"
  end

  def subteam_reference(rid)
    return unless (subteam = Subteam.find_with_team(team_rid, rid))
    "#{PROF_PREFIX}#{subteam.handle}"
  end

  def channel_reference(rid)
    return unless (channel = Channel.find_with_team(team_rid, rid))
    "#{CHAN_PREFIX}#{channel.name}"
  end
end
