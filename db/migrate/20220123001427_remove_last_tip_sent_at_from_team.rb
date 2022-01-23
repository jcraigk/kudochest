# frozen_string_literal: true
class RemoveLastTipSentAtFromTeam < ActiveRecord::Migration[7.0]
  def change
    remove_column :teams, :last_tip_sent_at, :datetime
  end
end
