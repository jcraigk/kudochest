# frozen_string_literal: true
class AddAppHomeOpenedAtToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :profiles, :welcomed_at, :datetime
  end
end
