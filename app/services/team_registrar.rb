# frozen_string_literal: true
class TeamRegistrar < Base::Service
  option :platform
  option :rid
  option :name
  option :avatar_url
  option :api_key
  option :owner_user_id

  def call
    create_or_update_team.tap { |team| team&.sync_remote(first_run: true) }
  end

  private

  def create_or_update_team
    return if Team.active.count >= App.max_teams
    return existing_team.tap { |team| team.update!(update_attrs) } if existing_team
    Team.create!(new_attrs)
  end

  def existing_team
    @existing_team ||= Team.find_by(rid:)
  end

  def new_attrs
    {
      platform:,
      rid:,
      response_mode:
    }.merge(update_attrs).merge(discord_attrs)
  end

  def discord_attrs
    return {} unless platform == :discord
    {
      tip_emoji: App.discord_tip_emoji,
      ditto_emoji: App.discord_ditto_emoji
    }
  end

  def update_attrs
    {
      name: name,
      avatar_url: avatar_url,
      owner_user_id: owner_user_id,
      api_key: api_key,
      installed: true
    }
  end

  def response_mode
    case platform
    when :slack then :adaptive
    when :discord then :convo
    end
  end
end
