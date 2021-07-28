# frozen_string_literal: true
class CreateTeams < ActiveRecord::Migration[6.0]
  def change
    create_table :teams do |t|
      t.integer :owner_user_id
      t.string :rid, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.string :avatar_url, null: false
      t.string :api_key, null: false
      t.boolean :throttle_tips, null: false
      t.integer :max_points_per_tip, null: false
      t.integer :token_hour, null: false
      t.string :token_frequency, null: false
      t.integer :token_quantity, null: false
      t.integer :token_max, null: false
      t.integer :member_count, null: false
      t.string :response_mode
      t.string :log_channel_rid
      t.string :tip_notes, null: false
      t.string :tip_emoji, null: false
      t.boolean :enable_emoji, null: false
      t.boolean :show_stats, null: false
      t.boolean :show_channel, null: false
      t.integer :work_days_mask, null: false
      t.string :week_start_day, null: false
      t.boolean :enable_levels, null: false
      t.string :level_curve, null: false
      t.integer :max_level, null: false
      t.integer :max_level_points, null: false
      t.datetime :tokens_disbursed_at
      t.integer :points_sent, null: false
      t.boolean :active, null: false
      t.boolean :enable_streaks, null: false
      t.integer :streak_duration, null: false
      t.integer :streak_reward, null: false
      t.timestamps
    end

    add_index :teams, :api_key, unique: true
    add_index :teams, :rid, unique: true
    add_index :teams, :slug, unique: true
    add_index :teams, :name
    add_index :teams, :owner_user_id
    add_index :teams, :token_hour
  end
end
