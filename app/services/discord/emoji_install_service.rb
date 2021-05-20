# frozen_string_literal: true
class Discord::EmojiInstallService < Base::Service
  option :team

  IMAGE_FILE = 'lib/emoji/discord_plus_one.png'

  def call
    delete_existing_emoji
    install_emoji
  end

  private

  def delete_existing_emoji
    return unless existing_emoji_id
    Discordrb::API::Server.delete_emoji(App.discord_token, team.rid, existing_emoji_id)
  end

  def existing_emoji_id
    @existing_emoji_id ||=
      JSON.parse(
        Discordrb::API::Server.resolve(App.discord_token, team.rid),
        object_class: OpenStruct
      ).emojis.find { |emoji| emoji.name == App.discord_emoji }&.id
  end

  def install_emoji
    team.update!(karma_emoji: new_remote_emoji.id)
  end

  def new_remote_emoji
    JSON.parse(
      Discordrb::API::Server.add_emoji(App.discord_token, team.rid, emoji_data, App.discord_emoji),
      object_class: OpenStruct
    )
  end

  def emoji_data
    image = File.open(IMAGE_FILE).read
    "data:image/png;base64,#{Base64.encode64(image)}"
  end
end
