# frozen_string_literal: true
class AddTopicIdToTips < ActiveRecord::Migration[6.0]
  def change
    add_column :tips, :topic_id, :uuid
    add_index :tips, :topic_id
  end
end
