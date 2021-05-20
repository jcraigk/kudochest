# frozen_string_literal: true
class ConvertQuantitiesToDecimal < ActiveRecord::Migration[6.0]
  def change
    change_column :tips, :quantity, :decimal, precision: 9, scale: 2
    change_column :teams, :karma_sent, :decimal, precision: 9, scale: 2
    change_column :profiles, :karma_sent, :decimal, precision: 9, scale: 2
    change_column :profiles, :karma_received, :decimal, precision: 9, scale: 2
    change_column :profiles, :tokens_forfeited, :decimal, precision: 9, scale: 2
    add_column :teams, :karma_increment, :decimal, precision: 4, scale: 2
    add_column :teams, :emoji_quantity, :decimal, precision: 4, scale: 2
    add_column :teams, :split_tip, :boolean, null: false, default: false
  end
end
