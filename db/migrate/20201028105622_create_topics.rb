# frozen_string_literal: true
class CreateTopics < ActiveRecord::Migration[6.0]
  def change
    create_table :topics, id: :uuid do |t|
      t.bigint :team_id, null: false
      t.string :name, null: false
      t.text :description
      t.string :keyword, null: false
      t.string :emoji
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :topics, :team_id
    add_index :topics, %i[team_id name], unique: true
    add_index :topics, %i[team_id keyword], unique: true
    add_index :topics, %i[team_id emoji], unique: true
  end
end
