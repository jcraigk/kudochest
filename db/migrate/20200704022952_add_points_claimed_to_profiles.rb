# frozen_string_literal: true
class AddPointsClaimedToProfiles < ActiveRecord::Migration[6.0]
  def change
    add_column :profiles, :points_claimed, :integer, null: false, default: 0
  end
end
