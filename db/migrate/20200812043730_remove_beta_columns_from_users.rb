class RemoveBetaColumnsFromUsers < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :beta_approved, :boolean
    remove_column :users, :beta_request, :text
  end
end
