class AddHintColumnsToTeams < ActiveRecord::Migration[6.1]
  def change
    add_column :teams, :hint_frequency, :string, null: false, default: 'never'
    add_column :teams, :hint_channel_rid, :string
    add_column :teams, :hint_posted_at, :datetime
  end
end
