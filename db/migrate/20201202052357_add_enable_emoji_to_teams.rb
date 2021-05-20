# frozen_string_literal: true
class AddEnableEmojiToTeams < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :enable_emoji, :boolean, null: false, default: true
    Team.where(emoji_quantity: 0).update_all(emoji_quantity: 1, enable_emoji: false)
  end
end
