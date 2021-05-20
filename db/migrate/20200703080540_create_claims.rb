# frozen_string_literal: true
class CreateClaims < ActiveRecord::Migration[6.0]
  def change
    create_table :claims, id: :uuid do |t|
      t.integer :profile_id
      t.uuid :reward_id
      t.integer :price
      t.string :fulfillment_key
      t.timestamp :fulfilled_at
      t.timestamps
    end

    add_index :claims, %i[profile_id reward_id fulfillment_key], unique: true
    add_index :claims, :created_at
  end
end
