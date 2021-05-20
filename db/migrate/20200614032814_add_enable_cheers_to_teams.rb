# frozen_string_literal: true
class AddEnableCheersToTeams < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :enable_cheers, :boolean, null: false, default: true
  end
end
