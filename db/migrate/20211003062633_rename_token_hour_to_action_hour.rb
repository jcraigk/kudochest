# frozen_string_literal: true
class RenameTokenHourToActionHour < ActiveRecord::Migration[6.1]
  def up
    remove_index :teams, :token_hour
    rename_column :teams, :token_hour, :action_hour
    add_index :teams, :action_hour
  end

  def down
    remove_index :teams, :action_hour
    rename_column :teams, :action_hour, :token_hour
    add_index :teams, :token_hour
  end
end
