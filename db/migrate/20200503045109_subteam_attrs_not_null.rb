class SubteamAttrsNotNull < ActiveRecord::Migration[6.0]
  def change
    change_column_null :subteams, :description, true
    change_column_null :subteams, :handle, true
  end
end
