# frozen_string_literal: true
class EmojiInstallWorker
  include Sidekiq::Worker
  sidekiq_options queue: :team_sync

  def perform(team_rid)
    team = Team.find_by!(rid: team_rid)
    Discord::EmojiInstallService.call(team: team)
  end
end
