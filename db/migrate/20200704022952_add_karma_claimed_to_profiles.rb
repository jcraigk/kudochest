# frozen_string_literal: true
class AddKarmaClaimedToProfiles < ActiveRecord::Migration[6.0]
  def change
    add_column :profiles, :karma_claimed, :integer, null: false, default: 0
  end
end
