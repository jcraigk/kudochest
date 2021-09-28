# frozen_string_literal
class AddLastTipSentAtToTeams < ActiveRecord::Migration[6.1]
  def change
    add_column :teams, :last_tip_sent_at, :datetime
  end
end
