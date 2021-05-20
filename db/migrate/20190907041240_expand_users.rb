# frozen_string_literal: true
class ExpandUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :reg_token, :string, null: false
    add_column :users, :subscribe_newsletter, :boolean, null: false
    add_column :users, :admin, :boolean, null: false
    add_column :users, :beta_approved, :boolean, null: false
    add_column :users, :beta_request, :text
    add_column :users, :theme, :string

    add_index :users, :reg_token, unique: true
  end
end
