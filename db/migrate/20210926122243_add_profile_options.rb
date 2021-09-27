# frozen_string_literal: true
class AddProfileOptions < ActiveRecord::Migration[6.1]
  def change
    add_column :profiles, :announce_tip_sent, :boolean, default: true, null: false
    add_column :profiles, :announce_tip_received, :boolean, default: true, null: false
    add_column :profiles, :share_history, :boolean, default: true, null: false
  end
end
