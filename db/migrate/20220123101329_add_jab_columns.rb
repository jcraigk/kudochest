# frozen_string_literal: true
class AddJabColumns < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :jabs_sent, :decimal, precision: 9, scale: 2, default: 0.0
    add_column :teams, :balance, :decimal, precision: 9, scale: 2, default: 0.0
    add_column :teams, :enable_jabs, :boolean, null: true, default: false
    add_column :teams, :deduct_jabs, :boolean, null: true, default: false
    add_column :teams, :jab_emoji, :string, null: false, default: App.default_jab_emoji
    add_column :profiles, :jabs_sent, :decimal, precision: 9, scale: 2, index: true, default: 0.0
    add_column :profiles, :jabs_received, :decimal, precision: 9, scale: 2, index: true, default: 0.0
    add_column :profiles, :balance, :decimal, precision: 9, scale: 2, index: true, default: 0.0
    rename_column :teams, :tip_emoji, :point_emoji
  end
end
