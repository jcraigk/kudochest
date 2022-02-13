# frozen_string_literal: true
class Base::ChannelMemberService < Base::Service
  option :team
  option :channel_rid

  def call
    sorted_local_profiles
  end

  private

  def sorted_local_profiles
    profiles.active.sort_by(&:display_name)
  end

  def profiles
    @profiles ||= team.profiles.active.where(rid: remote_rids).order(display_name: :asc)
  end

  def remote_rids
    @remote_rids ||=
      Rails.cache.fetch(
        "channel_members/#{team.id}/#{channel_rid}",
        expires_in: Time.current + App.channel_cache_ttl
      ) do
        channel_members
      end
  end
end
