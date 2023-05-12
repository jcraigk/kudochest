class AddWeeklyReportColumns < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :weekly_report, :boolean, null: false, default: true
    add_column :profiles, :weekly_report, :boolean, null: false, default: false
  end
end
