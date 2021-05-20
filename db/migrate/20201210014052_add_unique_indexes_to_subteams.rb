# frozen_string_literal: true
class AddUniqueIndexesToSubteams < ActiveRecord::Migration[6.1]
  def change
    add_index :subteams, %i[name team_id], unique: true
    add_index :subteams, %i[handle team_id], unique: true
    remove_index :subteams, name: 'index_subteams_on_handle'
    remove_index :subteams, name: 'index_subteams_on_name'
  end
end
