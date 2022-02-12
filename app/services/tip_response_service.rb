# frozen_string_literal: true

# TODO: Break this into multiple services
class TipResponseService < Base::Service # rubocop:disable Metrics/ClassLength
  include EmojiHelper
  include EntityReferenceHelper
  include PointsHelper

  RELEVANT_SOURCES = %w[
    modal inline point_reaction jab_reaction ditto_reaction topic_reaction reply
  ].freeze
  ANON_WORD = 'someone'

  option :tips

  def call
    build_response
  end

  private

  def build_response
    TipResponse.new \
      chat_fragments: build_fragments(team.platform.to_sym),
      image_fragments: build_fragments(:image),
      web: web_sentence
  end

  def web_sentence
    return unless tips.any?
    <<~TEXT.squish
      <span class="ts">#{current_time_in_zone.strftime('%b %-d %-l:%M%P')}:</span>
      #{formatted_web_str}
    TEXT
  end

  def formatted_web_str # rubocop:disable Metrics/AbcSize
    frags = build_fragments(:web)
    frags.reject! { |k, _v| k == :channel } unless team.show_channel?
    frags.reject! { |k, _v| k == :note } unless team.show_note?
    if frags[:channel].present?
      frags[:main] += " #{frags[:channel]}"
      frags.delete(:channel)
    end
    emojify(frags.values.compact.join(tag.br).strip, size: 12)
  end

  def current_time_in_zone
    Time.use_zone(team.time_zone) { Time.current }
  end

  def build_fragments(medium)
    {
      lead: lead_fragment(medium),
      main: main_fragment(medium),
      channel: channel_fragment(medium),
      note: note_fragment(medium),
      leveling: leveling_fragment(medium),
      streak: streak_fragment(medium)
    }
  end

  def main_fragment(medium)
    [
      profile_ref(medium, from_profile),
      points_fragment(medium)
    ].compact.join(' ')
  end

  def lead_fragment(medium)
    everyone_lead || entity_lead(medium)
  end

  # Lead with "Everyone in X has received points" if X is the only aggregate entity mention
  def entity_lead(medium)
    channel_leader = channel_lead(medium)
    subteam_leader = subteam_lead(medium)
    channel_leader.presence || subteam_leader.presence # Favor channel over subteam mention
  end

  def channel_lead(medium)
    return @channel_lead if @channel_lead.present?
    return unless unique_channel_tips.one?
    tip = unique_channel_tips.first
    channel_ref = channel_ref(medium, tip.to_channel_rid, tip.to_channel_name)
    @channel_lead = "Everyone in #{channel_ref} has received #{points_term(tip)}"
  end

  def points_term(tip)
    tip.jab? ? "*#{App.jabs_term}*" : App.points_term
  end

  def quiet_theme?
    @quiet_theme ||= team.response_theme.to_sym.in?(%i[quiet quiet_stat])
  end

  def subteam_lead(medium)
    return unless unique_subteam_tips.one?
    tip = unique_subteam_tips.first
    subteam_ref =
      if quiet_theme?
        Subteam.find_by(team:, rid: tip.to_subteam_rid).name
      else
        subteam_ref(medium, tip.to_subteam_rid, tip.to_subteam_handle)
      end
    "Everyone in #{subteam_ref} has received #{points_term(tip)}"
  end

  def everyone_lead
    return if (tip = tips.find(&:to_everyone?)).blank?
    "Everyone has received #{points_term(tip)}"
  end

  def unique_channel_tips
    @unique_channel_tips ||= tips.select(&:to_channel_rid).uniq(&:to_channel_rid)
  end

  def unique_subteam_tips
    @unique_subteam_tips ||= tips.select(&:to_subteam_rid).uniq(&:to_subteam_rid)
  end

  def channel_ref(medium, rid, name)
    case medium
    when :slack then name == SLACK_DM_NAME ? SLACK_DM_PHRASE : channel_link(rid)
    when :discord then channel_link(rid)
    when :image then "#{IMG_DELIM}#{CHAN_PREFIX}#{name} #{IMG_DELIM}"
    when :web then channel_webref(name)
    end
  end

  def subteam_ref(medium, rid, handle)
    case medium
    when :slack, :discord then "<#{SUBTEAM_PREFIX[medium]}#{rid}>"
    when :image then "#{IMG_DELIM}#{CHAN_PREFIX}#{handle} #{IMG_DELIM}" # TODO: test this
    when :web then subteam_webref(handle)
    end
  end

  def profile_ref(medium, profile, new_points = nil)
    return ANON_WORD unless profile.announce_tip_received?

    if new_points
      value_col = profile.team.enable_jabs? ? :balance : :points_received
      profile.send("#{value_col}=", new_points)
    end
    case medium
    when :slack, :discord then chat_profile_link(profile)
    when :image then "#{IMG_DELIM}#{profile.display_name} #{IMG_DELIM}"
    when :web then profile.web_profile_link
    end
  end

  def chat_profile_link(profile)
    case team.response_theme.to_sym
    when :quiet then profile.dashboard_link
    when :quiet_stat then profile.dashboard_link_with_stat
    when :fancy then profile.link_with_stat
    when :basic then profile.link
    end
  end

  def streak_fragment(medium)
    return unless streak_rewarded?
    <<~TEXT.squish
      #{profile_ref(medium, from_profile)} earned #{points_format(team.streak_reward, label: true)} for achieving a Giving Streak of #{number_with_delimiter(from_profile.streak_count)} days
    TEXT
  end

  def from_profile
    @from_profile ||= first_tip.from_profile
  end

  def first_tip
    @first_tip ||= tips.first
  end

  def streak_rewarded?
    return false unless tips.any? { |tip| tip.quantity.positive? } # Do not reward jabs
    return @streak_rewarded unless @streak_rewarded.nil?
    @streak_rewarded = StreakRewardService.call \
      profile: from_profile,
      event_ts: first_tip.event_ts
  end

  def leveling_fragment(medium)
    return unless team.enable_levels? && levelings.any?
    [levelup_fragment(medium), leveldown_fragment(medium)].compact_blank.join(' and ')
  end

  def levelup_fragment(medium)
    if levelups.one?
      profile = levelups.first.profile
      "#{profile_ref(medium, profile)} leveled up to #{profile.level}!"
    elsif levelups.any?
      "#{leveling_profiles(medium, levelups)} leveled up!"
    end
  end

  def leveldown_fragment(medium)
    if leveldowns.one?
      profile = leveldowns.first.profile
      "#{profile_ref(medium, profile)} leveled down to #{profile.level}!"
    elsif leveldowns.any?
      "#{leveling_profiles(medium, levelups)} leveled down!"
    end
  end

  def levelups
    @levelups ||= levelings.select { |l| l.delta.positive? }
  end

  def leveldowns
    @leveldowns ||= levelings.select { |l| l.delta.negative? }
  end

  # TODO: DRY up these leveling methods
  def sender_leveling
    return unless streak_rewarded?
    points = from_profile.send(value_col)
    new_points = points + team.streak_reward
    delta = level_for(new_points) - level_for(points)
    ProfileLeveling.new(from_profile, new_points, delta) unless delta.zero?
  end

  def recipient_levelings
    tips_by_recipient.map do |prof, prof_tips|
      points = prof.send(value_col)
      prof_tips = select_positive_tips(prof_tips) unless team.deduct_jabs?
      delta = level_for(points) - level_for(points - prof_tips.sum(&:quantity))
      ProfileLeveling.new(prof, points, delta) unless delta.zero?
    end
  end

  def value_col
    @value_col ||= team.deduct_jabs? ? :balance : :points_received
  end

  def levelings
    @levelings ||= (recipient_levelings + [sender_leveling]).compact
  end

  def select_positive_tips(prof_tips)
    prof_tips.select { |tip| tip.quantity.positive? }
  end

  def tips_by_recipient
    tips.group_by(&:to_profile)
  end

  def level_for(points)
    PointsToLevelService.call(team:, points:)
  end

  def leveling_profiles(medium, levelings)
    return "#{levelings.size} users" if levelings.size > 3
    levelings.map { |leveling| profile_ref(medium, leveling.profile) }.to_sentence
  end

  def points_fragment(medium)
    return if tips_by_quantity.none?
    "gave #{points_clause(medium)}"
  end

  def points_clause(medium)
    tips_by_quantity.map do |quantity, quantity_tips|
      quantity_tips.group_by(&:topic_id).map do |topic_id, similar_tips|
        str = compose_str(medium, quantity, topic_id, similar_tips)
        str += ' each' if similar_tips.size > 1
        str
      end
    end.flatten.to_sentence
  end

  def channel_fragment(medium)
    case medium
    when :slack, :discord then "in <#{CHAN_PREFIX}#{first_tip.from_channel_rid}>"
    when :web then "in #{channel_webref(first_tip.from_channel_name)}"
    end
  end

  def compose_str(medium, quantity, topic_id, similar_tips)
    recipient_sentence = profile_sentence(profile_refs_from(medium, similar_tips))
    topic = team.topics.find { |t| t.id == topic_id }
    emoji = emoji_sequence(medium, quantity, topic)
    topic_str = topic&.name ? "for _#{topic.name}_" : nil
    "#{recipient_sentence} #{points_format(quantity, label: true, bold_jab: true)} " \
    "#{emoji} #{topic_str}".squish
  end

  def profile_sentence(refs)
    return "#{refs.size} users" if refs.size > App.max_response_mentions
    refs.to_sentence
  end

  def emoji_sequence(medium, quantity, topic)
    return if medium == :image || !team.response_theme.fancy?
    return ":#{topic.emoji}:" * quantity if topic&.emoji
    team.point_emoj * quantity
  end

  def profile_refs_from(medium, quantity_tips)
    quantity_tips.map do |tip|
      new_points = levelings.find { |leveling| leveling.profile == tip.to_profile }&.new_points
      profile_ref(medium, tip.to_profile, new_points)
    end
  end

  def tips_by_quantity
    tips.select { |tip| tip.source.in?(RELEVANT_SOURCES) }
        .group_by(&:quantity)
        .sort
        .reverse
  end

  def team
    @team ||= from_profile.team
  end

  def note_fragment(medium)
    return if note.blank?
    "Note: #{formatted_note(medium)}"
  end

  def formatted_note(medium)
    case medium
    when :image then note
    when :slack then "_#{note}_"
    when :discord then "*#{note}*"
    when :web then "<i>#{note}</i>"
    end
  end

  def note
    @note ||= first_tip.note
  end

  ProfileLeveling = Struct.new(:profile, :new_points, :delta)
  TipResponse = Struct.new(:chat_fragments, :image_fragments, :web, keyword_init: true)
end
