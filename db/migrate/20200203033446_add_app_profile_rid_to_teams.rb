# frozen_string_literal: true
class AddAppProfileRidToTeams < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :app_profile_rid, :string
    remove_column :profiles, :app_user, :boolean
  end
end
