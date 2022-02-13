# frozen_string_literal: true
class TipFactory < Base::Service
  option :event_ts
  option :message_ts, default: -> {}
  option :from_channel_name
  option :from_channel_rid
  option :from_profile
  option :note
  option :quantity
  option :topic_id
  option :source
  option :to_entity
  option :to_profiles
  option :timestamp

  def call
    Tip.transaction do
      create_tips
    end
  end

  private

  def create_tips
    to_profiles.map do |profile|
      attrs = base_attrs.merge(to_profile: profile).merge(entity_attrs)
      Tip.create!(attrs).tap do |tip|
        fetch_permalink_async(tip.id) if fetch_permalink?(tip.source)
      end
    end
  end

  def fetch_permalink_async(tip_id)
    ChatPermalinkWorker.perform_async(tip_id, from_channel_rid, message_ts || event_ts)
  end

  def fetch_permalink?(source)
    team.platform.slack? &&
      source.in?(ChatPermalinkWorker::SOURCES) &&
      from_channel_rid.present? &&
      (message_ts.present? || event_ts.present?)
  end

  def base_attrs # rubocop:disable Metrics/MethodLength
    {
      created_at: timestamp,
      event_ts:,
      from_channel_name: from_channel,
      from_channel_rid:,
      from_profile:,
      note: truncated_note,
      quantity: tip_quantity,
      source:,
      topic_id:
    }
  end

  def tip_quantity
    num_profiles = to_profiles.size
    return quantity unless team.split_tip? && num_profiles > 1
    floor_increment((quantity / num_profiles.to_f), team.tip_increment)
  end

  def from_channel
    channel_name_abbrev(from_channel_name) || Channel.find_by(rid: from_channel_rid)&.name
  end

  def channel_name_abbrev(name)
    return SLACK_DM_NAME if team.platform.slack? && name&.start_with?(SLACK_DM_PREFIX)
    name.presence
  end

  def entity_attrs
    return { to_everyone: true } if to_entity == 'everyone'
    case to_entity.class.name
    when 'Subteam' then subteam_attrs
    when 'Channel' then named_channel_attrs
    else {}
    end
  end

  def named_channel_attrs
    {
      to_channel_rid: to_entity.rid,
      to_channel_name: channel_name_abbrev(to_entity.name)
    }
  end

  def subteam_attrs
    {
      to_subteam_rid: to_entity.rid,
      to_subteam_handle: to_entity.handle || to_entity.name
    }
  end

  def truncated_note
    return '' if team.tip_notes.disabled?
    truncate(note, length: App.max_note_length, escape: false)
  end

  def team
    @team ||= from_profile.team
  end
end
