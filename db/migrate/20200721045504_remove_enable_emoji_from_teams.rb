class RemoveEnableEmojiFromTeams < ActiveRecord::Migration[6.0]
  def change
    remove_column :teams, :enable_emoji, :boolean
  end
end
