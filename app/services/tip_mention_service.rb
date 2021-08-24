# frozen_string_literal: true
class TipMentionService < Base::Service
  option :channel_name
  option :channel_rid
  option :event_ts
  option :mentions
  option :profile
  option :source
  option :note, default: proc {}

  def call
    return respond_need_tokens if need_tokens?
    return respond_note_required if note_missing?
    return respond_no_action if tips.none?

    respond_success
  end

  private

  def respond_no_action
    OpenStruct.new(
      mode: :error,
      text: I18n.t('errors.no_tips', points: App.points_term)
    )
  end

  def tips
    @tips ||= Tip.transaction do
      uniq_entity_mentions.map do |mention|
        next if mention.profiles.none?
        create_tips_for(mention, timestamp)
      end.flatten.compact
    end
  end

  def create_tips_for(mention, timestamp) # rubocop:disable Metrics/MethodLength
    TipFactory.call(
      topic_id: mention.topic_id,
      event_ts: event_ts,
      from_channel_name: channel_name,
      from_channel_rid: channel_rid,
      from_profile: profile,
      note: note,
      quantity: mention.quantity,
      source: source,
      to_entity: mention.entity,
      to_profiles: mention.profiles,
      timestamp: timestamp
    )
  end

  def timestamp
    @timestamp ||= Time.current
  end

  def respond_success
    OpenStruct.new(
      mode: :public,
      response: response,
      tips: tips,
      image: response_image
    )
  end

  def response_image
    return unless team.response_theme.start_with?('gif') && tips.any?
    ResponseImageService.call(
      type: 'tip',
      team_config: team.config,
      fragments: response.image_fragments,
      tips: tips
    )
  end

  def response
    @response = TipResponseService.call(tips: tips)
  end

  def respond_need_tokens
    OpenStruct.new(mode: :error, text: @need_tokens)
  end

  def respond_note_required
    OpenStruct.new(mode: :error, text: I18n.t('tips.note_required'))
  end

  def fetch_entity(rid)
    if rid == 'everyone' then rid
    elsif rid == 'channel' then channel_entity(channel_rid.delete(CHAN_PREFIX))
    elsif rid.start_with?(*SUBTEAM_PREFIX.values) then subteam_entity(rid)
    elsif rid.start_with?(PROF_PREFIX) then profile_entity(rid)
    elsif rid.start_with?(CHAN_PREFIX) then channel_entity(rid)
    end
  end

  def channel_entity(rid)
    rid = rid.delete(CHAN_PREFIX)
    Channel.find_with_team(team.rid, rid) || Channel.new(name: channel_name, rid: rid)
  end

  def profile_entity(rid)
    Profile.find_with_team(team.rid, rid.delete(PROFILE_PREFIX[:discord])) # Handles Slack too
  end

  def subteam_entity(rid)
    raw_rid = rid.delete(SUBTEAM_PREFIX[:discord]).gsub(SUBTEAM_PREFIX[:slack], '')
    Subteam.find_with_team(team.rid, raw_rid)
  end

  def profiles_for_entity(entity)
    return team.profiles.active.where.not(rid: profile.rid) if entity == 'everyone'
    case entity.class.name
    when 'Profile' then [entity]
    when 'Subteam' then subteam_profiles(entity)
    when 'Channel' then channel_profiles(entity)
    end
  end

  def channel_profiles(channel)
    "#{team.plat}::ChannelMemberService".constantize.call(
      team: team,
      channel_rid: channel.rid
    ).reject { |prof| prof.id == profile.id }
  end

  def subteam_profiles(subteam)
    subteam.profiles.active.where.not(id: profile.id).to_a
  end

  def uniq_entity_mentions
    return [everyone_mention] if everyone_mention.present?

    # Ensure each profile is mentioned only once
    # Prefer direct mention, then subteam, then channel
    profile_mentions + sanitized_subteam_mentions + sanitized_channel_mentions
  end

  def profile_mentions
    entity_mentions.select { |m| m.entity.is_a?(Profile) }
  end

  def everyone_mention
    entity_mentions.find { |m| m.entity == 'everyone' }
  end

  def channel_mention
    entity_mentions.find { |m| m.entity == 'channel' }
  end

  def sanitized_channel_mentions
    channel_mentions.map do |mention|
      mention.tap do |m|
        m.profiles.reject! { |prof| prof.rid.in?(profile_mention_rids + subteam_mention_rids) }
      end
    end
  end

  def sanitized_subteam_mentions
    subteam_mentions.map do |mention|
      mention.tap do |m|
        m.profiles.reject! { |prof| prof.rid.in?(profile_mention_rids) }
      end
    end
  end

  def profile_mention_rids
    @profile_mention_rids ||= profile_mentions.map(&:entity).map(&:rid)
  end

  def subteam_mention_rids
    @subteam_mention_rids ||= subteam_mentions.map(&:entity).map(&:profiles).flatten.map(&:rid)
  end

  def subteam_mentions
    @subteam_mentions ||= entity_mentions.select { |m| m.entity.is_a?(Subteam) }
  end

  def channel_mentions
    @channel_mentions ||= entity_mentions.select { |m| m.entity.is_a?(Channel) }
  end

  def entity_mentions
    @entity_mentions ||= mentions.filter_map do |mention|
      next unless (entity = fetch_entity(mention.rid))
      OpenStruct.new(
        entity: entity,
        profiles: profiles_for_entity(entity),
        topic_id: mention.topic_id,
        quantity: mention.quantity
      )
    end
  end

  def need_tokens?
    quantity = entity_mentions.sum { |m| mention_quantity(m) }
    @need_tokens = TokenLimitService.call(profile: profile, quantity: quantity)
  end

  def mention_quantity(mention)
    quantity = mention.quantity
    num_profiles = mention.profiles.size
    if team.split_tip?
      floor_increment((quantity / num_profiles.to_f), team.tip_increment)
    else
      quantity * num_profiles
    end
  end

  def note_missing?
    team.tip_notes.required? && note.blank?
  end

  def team
    @team ||= profile.team
  end
end
