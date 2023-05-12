class CreateProfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :profiles do |t|
      t.references :team
      t.references :user, optional: true
      t.string :rid, null: false
      t.string :display_name, null: false
      t.string :real_name, null: false
      t.string :title
      t.string :slug, null: false
      t.string :avatar_url, null: false
      t.string :reg_token, null: false
      t.boolean :bot_user, null: false
      t.boolean :app_user, null: false
      t.boolean :restricted, null: false
      t.boolean :deleted, null: false
      t.boolean :allow_unprompted_dm, null: false
      t.boolean :infinite_tokens, null: false
      t.integer :tokens_accrued, null: false
      t.integer :tokens_forfeited, null: false
      t.integer :points_received, null: false
      t.integer :points_sent, null: false
      t.datetime :last_tip_received_at
      t.date :streak_date
      t.integer :streak_count, null: false
      t.timestamps
    end

    add_index :profiles, %i[rid team_id], unique: true
    add_index :profiles, :display_name
    add_index :profiles, :slug, unique: true
    add_index :profiles, :created_at
    add_index :profiles, :reg_token, unique: true
    add_index :profiles, :points_received
    add_index :profiles, :points_sent
    add_index :profiles, :last_tip_received_at
  end
end
