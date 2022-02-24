# frozen_string_literal: true
class AddToHereToTips < ActiveRecord::Migration[7.0]
  def change
    add_column :tips, :to_here, :boolean, default: false
  end
end
