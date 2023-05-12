class AddEnableFastAckToTeams < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :enable_fast_ack, :boolean
    Team.update_all(enable_fast_ack: true)
    change_column_null :teams, :enable_fast_ack, false
  end
end
