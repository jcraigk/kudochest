class AddLastTipSentAtToProfiles < ActiveRecord::Migration[6.0]
  def change
    add_column :profiles, :last_tip_sent_at, :datetime
  end
end
