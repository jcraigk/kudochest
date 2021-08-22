# frozen_string_literal: true
class Discord::PostService < Base::PostService
  private

  def post_response
    @post_response ||= JSON.parse(respond_in_discord, object_class: OpenStruct)
  end

  def respond_in_discord
    case mode
    when :error, :private, :direct then respond_dm(profile_rid)
    when :public then respond_in_convo(channel_rid)
    end
  end

  def respond_in_convo(channel)
    if image.present?
      content = File.open(image, 'rb')
      result = Discordrb::API::Channel.upload_file(App.discord_token, channel, content)
      File.delete(image)
      return result
    end

    Discordrb::API::Channel.create_message(App.discord_token, channel, chat_response_text)
  end

  def respond_dm(profile_rid)
    dm_channel = JSON[Discordrb::API::User.create_pm(App.discord_token, profile_rid)]['id']
    respond_in_convo(dm_channel)
  end

  def post_response_channel_rid
    post_response.channel_id
  end

  def post_response_ts
    post_response.id
  end

  def fast_ack_text
    nil
  end
end
