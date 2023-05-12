class RemoveRestrictedFromProfiles < ActiveRecord::Migration[6.0]
  def change
    remove_column :profiles, :restricted, :boolean, null: false
  end
end
