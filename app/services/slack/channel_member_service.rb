class Slack::ChannelMemberService < Base::ChannelMemberService
  private

  def channel_members
    here ? online_members : all_members
  end

  def all_members
    @all_members ||= team.slack_client.conversations_members(channel: channel_rid)[:members]
  rescue Slack::Web::Api::Errors::ChannelNotFound # App has insufficient privileges
    []
  end

  def online_members
    all_members.select { |rid| member_online?(rid) }
  end

  def member_online?(rid)
    team.slack_client.users_getPresence(user: rid)[:presence] == 'active'
  rescue Slack::Web::Api::Errors::TooManyRequestsError
    raise ChatFeedback, I18n.t('slack.too_many_for_here')
  end
end
