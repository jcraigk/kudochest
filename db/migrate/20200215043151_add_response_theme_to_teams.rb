class AddResponseThemeToTeams < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :response_theme, :string
    remove_column :teams, :show_stats, :string
  end
end
