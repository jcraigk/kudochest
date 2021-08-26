# frozen_string_literal: true
class Discord::EmojiInstallService < Base::Service
  option :team

  EMOJI_TYPES = %i[tip ditto].freeze
  EMOJI_DIR = 'lib/emoji/discord'

  def call
    delete_existing_emojis
    install_new_emojis
  end

  private

  def delete_existing_emojis
    EMOJI_TYPES.each do |type|
      next unless (emoji_id = existing_emoji_id(type))
      Discordrb::API::Server.delete_emoji(App.discord_token, team.rid, emoji_id)
    end
  end

  def install_new_emojis
    EMOJI_TYPES.each { |type| create_emoji(type) }
  end

  def existing_emoji_id(type)
    fetch(
      Discordrb::API::Server.resolve(App.discord_token, team.rid)
    ).emojis.find { |emoji| emoji.name == App.send("discord_#{type}_emoji") }&.id
  end

  def create_emoji(type)
    fetch(
      Discordrb::API::Server.add_emoji(
        App.discord_token,
        team.rid,
        emoji_data(type),
        App.send("discord_#{type}_emoji")
      )
    )
  end

  def emoji_data(type)
    data = File.open("#{EMOJI_DIR}/#{type}.png").read
    "data:image/png;base64,#{Base64.encode64(data)}"
  end

  def fetch(request)
    JSON.parse(request, object_class: OpenStruct)
  end
end
