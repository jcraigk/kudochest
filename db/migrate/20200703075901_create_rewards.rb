# frozen_string_literal: true
class CreateRewards < ActiveRecord::Migration[6.0]
  def change
    create_table :rewards, id: :uuid do |t|
      t.integer :team_id
      t.string :name
      t.text :description
      t.integer :quantity
      t.integer :price
      t.boolean :auto_fulfill, null: false
      t.string :fulfillment_keys
      t.boolean :active, null: false
      t.timestamps
    end

    add_index :rewards, %i[team_id name], unique: true
  end
end
