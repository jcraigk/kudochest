class AddShowNoteInLogToTeams < ActiveRecord::Migration[6.1]
  def change
    add_column :teams, :show_note, :boolean, null: false, default: true
  end
end
