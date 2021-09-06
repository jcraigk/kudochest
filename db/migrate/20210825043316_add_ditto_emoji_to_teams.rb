# frozen_string_literal: true
class AddDittoEmojiToTeams < ActiveRecord::Migration[6.1]
  def change
    add_column :teams, :ditto_emoji, :string
  end
end
