# frozen_string_literal: true
class AddInstalledToTeams < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :installed, :boolean
    Team.update_all(installed: false)
    change_column_null :teams, :installed, false
  end
end
