# frozen_string_literal: true
class CreateSubteamMemberships < ActiveRecord::Migration[6.0]
  def change
    create_table :subteam_memberships, id: false do |t|
      t.references :profile
      t.references :subteam
    end

    add_index :subteam_memberships, %i[profile_id subteam_id], unique: true
  end
end
