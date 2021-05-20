# frozen_string_literal: true
class AddNotifyTokensDisbursedToTeams < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :notify_tokens_disbursed, :boolean
    Team.update_all(notify_tokens_disbursed: true)
    change_column_null :teams, :notify_tokens_disbursed, false
  end
end
