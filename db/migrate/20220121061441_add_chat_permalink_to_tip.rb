# frozen_string_literal: true
class AddChatPermalinkToTip < ActiveRecord::Migration[7.0]
  def change
    add_column :tips, :chat_permalink, :string
  end
end
