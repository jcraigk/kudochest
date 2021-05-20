# frozen_string_literal: true
class TipResponseService < Base::Service
  include EmojiHelper
  include EntityReferenceHelper
  include KarmaHelper

  option :tips

  def call
    build_response
  end

  private

  def build_response
    OpenStruct.new(
      chat_fragments: build_fragments(team.platform.to_sym),
      image_fragments: build_fragments(:image),
      web: web_sentence
    )
  end

  def web_sentence
    return unless tips.any?
    <<~TEXT.squish
      <span class="ts">#{current_time_in_zone.strftime('%b %-d %-l:%M%P')}:</span>
      #{formatted_web_str}
    TEXT
  end

  def formatted_web_str
    fragments = build_fragments(:web)
    text = fragments[1].delete_suffix('!')
    fragments[1] = "#{text} in #{channel_webref(tips.first.from_channel_name)}"
    emojify(fragments.compact.join(tag.br).strip, size: 12)
  end

  def current_time_in_zone
    Time.use_zone(team.time_zone) { Time.current }
  end

  def build_fragments(platform)
    [
      lead_fragment(platform),
      main_fragment(platform),
      note_fragment(platform),
      levelup_fragment(platform),
      streak_fragment(platform)
    ]
  end

  def main_fragment(platform)
    [
      profile_ref(from_profile, platform),
      karma_fragment(platform)
    ].compact.join(' ')
  end

  def lead_fragment(platform)
    everyone_lead || entity_lead(platform)
  end

  # Lead with "Everyone in X has received karma" if X is the only aggregate entity mention
  def entity_lead(platform)
    channel_leader = channel_lead(platform)
    subteam_leader = subteam_lead(platform)
    channel_leader.presence || subteam_leader.presence # Favor channel over subteam mention
  end

  def channel_lead(platform)
    return unless to_channels.one?
    channel = to_channels.first
    channel_ref = channel_ref(channel.rid, channel.name, platform)
    "Everyone in #{channel_ref} has received karma!"
  end

  def subteam_lead(platform)
    return unless to_subteams.one?
    subteam = to_subteams.first
    subteam_ref = subteam_ref(subteam.rid, subteam.handle, platform)
    "Everyone in #{subteam_ref} has received karma!"
  end

  def everyone_lead
    return if tips.find(&:to_everyone?).blank?
    'Everyone has received karma!'
  end

  def to_channels
    tips.select(&:to_channel_rid).uniq(&:to_channel_rid).map do |tip|
      OpenStruct.new(
        rid: tip.to_channel_rid,
        name: tip.to_channel_name
      )
    end
  end

  def to_subteams
    tips.select(&:to_subteam_rid).uniq(&:to_subteam_rid).map do |tip|
      OpenStruct.new(
        rid: tip.to_subteam_rid,
        handle: tip.to_subteam_handle
      )
    end
  end

  def channel_ref(rid, name, platform)
    case platform
    when :slack, :discord then channel_link(rid)
    when :image then "#{IMG_DELIM}#{CHAN_PREFIX}#{name} #{IMG_DELIM}"
    when :web then channel_webref(name)
    end
  end

  def subteam_ref(rid, handle, platform)
    case team.platform.to_sym
    when :slack, :discord then "<#{SUBTEAM_PREFIX[platform]}#{rid}>"
    when :image then "#{IMG_DELIM}#{CHAN_PREFIX}#{name} #{IMG_DELIM}"
    when :web then subteam_webref(handle)
    end
  end

  def profile_ref(profile, platform, new_karma = nil)
    profile.karma_received = new_karma if new_karma
    case platform
    when :slack, :discord then chat_profile_ref(profile)
    when :image then "#{IMG_DELIM}#{PROF_PREFIX}#{profile.display_name} #{IMG_DELIM}"
    when :web then web_profile_ref(profile)
    end
  end

  def chat_profile_ref(profile)
    case team.response_theme
    when 'unobtrusive' then unobtrusive_link(profile)
    when 'fancy' then profile.link_with_stat
    when 'basic' then profile.link
    end
  end

  def unobtrusive_link(profile)
    case profile.team.platform
    when 'slack' then "<#{profile.web_url}|#{profile.display_name}>"
    when 'discord' then "**#{profile.display_name}**"
    end
  end

  def web_profile_ref(profile)
    case team.response_theme
    when 'unobtrusive', 'basic' then profile.webref
    when 'fancy' then profile.webref_with_stat
    end
  end

  def streak_fragment(platform)
    return unless streak_rewarded?
    <<~TEXT.squish
      #{profile_ref(from_profile, platform)} earned #{team.streak_reward} bonus karma for achieving a Giving Streak of #{number_with_delimiter(from_profile.streak_count)} days
    TEXT
  end

  def from_profile
    @from_profile ||= first_tip.from_profile
  end

  def first_tip
    @first_tip ||= tips.first
  end

  def streak_rewarded?
    return @streak_rewarded unless @streak_rewarded.nil?
    @streak_rewarded = StreakRewardService.call(
      profile: from_profile,
      event_ts: first_tip.event_ts
    )
  end

  def levelup_fragment(platform)
    return unless team.enable_levels && levelups.any?
    "#{levelup_sentence(platform)} leveled up!"
  end

  def sender_profile_levelup
    return unless streak_rewarded?

    old_karma = from_profile.karma_received
    new_karma = old_karma + team.streak_reward
    return unless level_for(new_karma) > level_for(old_karma)

    OpenStruct.new(profile: from_profile, new_karma: new_karma)
  end

  def levelups
    @levelups ||= (
      tips.group_by(&:to_profile).map do |profile, profile_tips|
        old_karma = profile.karma_received
        new_karma = old_karma + profile_tips.sum(&:quantity)
        next unless level_for(new_karma) > level_for(old_karma)
        OpenStruct.new(profile: profile, new_karma: new_karma)
      end + [sender_profile_levelup]
    ).flatten.compact
  end

  def level_for(karma)
    KarmaToLevelService.call(team: team, karma: karma)
  end

  def levelup_sentence(platform)
    return "#{levelups.size} users" if levelups.size > 3
    levelups.map { |levelup| profile_ref(levelup.profile, platform) }.to_sentence
  end

  def karma_fragment(platform)
    return if tips_by_quantity.none?
    "gave #{karma_clause(platform)}"
  end

  def karma_clause(platform)
    fragments = tips_by_quantity.map do |quantity, quantity_tips|
      quantity_tips.group_by(&:topic_id).map do |topic_id, similar_tips|
        str = compose_str(platform, quantity, topic_id, similar_tips)
        str += ' each' if similar_tips.size > 1
        str
      end
    end.flatten
    "#{fragments.to_sentence}!"
  end

  def compose_str(platform, quantity, topic_id, similar_tips)
    recipient_sentence = profile_sentence(profile_refs_from(similar_tips, platform))
    quant_str = karma_format(quantity)
    topic = team.topics.find { |t| t.id == topic_id }
    emoji = emoji_sequence(platform, quantity, topic)
    topic_str = topic&.name ? "for #{topic.name}" : nil
    "#{recipient_sentence} #{quant_str} karma #{emoji} #{topic_str}".squish
  end

  def profile_sentence(refs)
    return "#{refs.size} users" if refs.size > App.max_response_mentions
    refs.to_sentence
  end

  def emoji_sequence(platform, quantity, topic)
    return if platform == :image || !team.response_theme.fancy?
    return ":#{topic.emoji}:" * quantity if topic&.emoji
    team.custom_emoj * quantity
  end

  def profile_refs_from(quantity_tips, platform)
    quantity_tips.map do |tip|
      new_karma = levelups.find { |levelup| levelup.profile == tip.to_profile }&.new_karma
      profile_ref(tip.to_profile, platform, new_karma)
    end
  end

  def tips_by_quantity
    tips.select { |tip| tip.source.in?(%w[modal plusplus reaction reply]) }
        .group_by(&:quantity)
        .sort
        .reverse
  end

  def team
    @team ||= from_profile.team
  end

  def note_fragment(platform)
    return if note.blank?
    "\"#{formatted_note(platform)}\""
  end

  def formatted_note(platform)
    case platform
    when :image then note # TODO: handle emojis?
    when :slack then "_#{note}_"
    when :discord then "*#{note}*"
    when :web then "<i>#{note}</i>"
    end
  end

  def note
    @note ||= first_tip.note
  end
end
