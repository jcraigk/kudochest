class Discord::EmojiInstallService < Base::Service
  option :team

  EMOJI_TYPES = %i[point jab ditto].freeze
  EMOJI_DIR = 'lib/emoji/discord'.freeze

  def call
    update_emojis
  end

  private

  def update_emojis
    EMOJI_TYPES.each do |type|
      delete_existing_emoji(type)
      create_new_emoji(type)
    end
  end

  def delete_existing_emoji(type)
    return unless (emoji_id = existing_emoji_id(type))
    Discordrb::API::Server.delete_emoji(App.discord_token, team.rid, emoji_id)
  end

  def existing_emoji_id(type)
    fetch(
      Discordrb::API::Server.resolve(App.discord_token, team.rid)
    )[:emojis].find { |emoji| emoji[:name] == App.send("discord_#{type}_emoji") }&.dig(:id)
  end

  def create_new_emoji(type)
    fetch \
      Discordrb::API::Server.add_emoji \
        App.discord_token,
        team.rid,
        emoji_data(type),
        App.send("discord_#{type}_emoji")
  end

  def emoji_data(type)
    data = File.read("#{EMOJI_DIR}/#{type}.png")
    "data:image/png;base64,#{Base64.encode64(data)}"
  end

  def fetch(request)
    return {} if request.blank?
    JSON.parse(request, symbolize_names: true)
  end
end
