class AddNotifyTokensDisbursedToTeams < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :notify_tokens, :boolean
    Team.update_all(notify_tokens: true)
    change_column_null :teams, :notify_tokens, false
  end
end
