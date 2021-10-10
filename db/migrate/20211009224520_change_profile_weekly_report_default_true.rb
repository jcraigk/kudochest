# frozen_string_literal: true
class ChangeProfileWeeklyReportDefaultTrue < ActiveRecord::Migration[6.1]
  def change
    change_column_default :profiles, :weekly_report, from: false, to: true
  end
end
