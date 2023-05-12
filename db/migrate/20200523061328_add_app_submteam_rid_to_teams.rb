class AddAppSubmteamRidToTeams < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :app_subteam_rid, :string
  end
end
