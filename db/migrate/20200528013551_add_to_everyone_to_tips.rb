# frozen_string_literal: true
class AddToEveryoneToTips < ActiveRecord::Migration[6.0]
  def change
    add_column :tips, :to_everyone, :boolean, default: false
  end
end
