# frozen_string_literal: true
class RemoveContestIdFromTips < ActiveRecord::Migration[6.1]
  def change
    remove_column :tips, :contest_id, :bigint
  end
end
