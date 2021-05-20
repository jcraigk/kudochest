# frozen_string_literal: true
class AddJoinChannelsToTeams < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :join_channels, :boolean, null: false, default: false
  end
end
