# frozen_string_literal: true
require 'csv'

class DataExportWorker
  include Sidekiq::Worker
  sidekiq_options queue: :data_export,
                  lock: :until_and_while_executing,
                  unique_args: ->(args) { [args.first] }

  attr_reader :team_id

  def perform(team_id)
    @team_id = team_id
    email_owner_with_csv_attachment
  end

  private

  def email_owner_with_csv_attachment
    TeamOwnerMailer.data_export(team, csv_str).deliver_later
  end

  def csv_str
    CSV.generate do |csv|
      csv << ['ID', 'Name', App.points_term.titleize]
      team.profiles.active.order(display_name: :asc).each do |profile|
        csv << csv_row(profile)
      end
    end
  end

  def csv_row(profile)
    [
      profile.rid,
      profile.display_name,
      profile.karma
    ]
  end

  def team
    @team ||= Team.find(team_id)
  end
end
