class AddEnableLootToTeams < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :enable_loot, :boolean, null: false, default: true
  end
end
