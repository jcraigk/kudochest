# frozen_string_literal: true
class CreateTips < ActiveRecord::Migration[6.0]
  def change
    create_table :tips do |t|
      t.references :contest
      t.integer :from_profile_id, null: false
      t.integer :to_profile_id, null: false
      t.string :source, null: false
      t.string :from_channel_rid
      t.string :from_channel_name
      t.integer :quantity, null: false
      t.string :event_ts, null: false
      t.string :note
      t.string :response_ts
      t.string :response_channel_rid
      t.string :to_channel_rid
      t.string :to_channel_name
      t.string :to_subteam_rid
      t.string :to_subteam_handle
      t.datetime :created_at
    end

    add_index :tips, :from_profile_id
    add_index :tips, :to_profile_id
    add_index :tips, :created_at
    add_index :tips, %i[event_ts to_profile_id], unique: true
    add_index :tips, :source
    add_index :tips, "date_trunc('day', created_at) ASC", name: 'idx_on_tips_created_at_truncated_to_day'
  end
end
