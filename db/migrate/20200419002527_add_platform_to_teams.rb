class AddPlatformToTeams < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :platform, :string, index: true
  end
end
