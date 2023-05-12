class AddTopicColsToTeams < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :enable_topics, :boolean, null: false, default: false
    add_column :teams, :require_topic, :boolean, null: false, default: false
  end
end
