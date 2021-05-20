# frozen_string_literal: true
class AddTimezoneToTeams < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :time_zone, :string, null: false, default: 'UTC'
  end
end
