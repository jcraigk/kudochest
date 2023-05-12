class RenameAllowUnpromptedDm < ActiveRecord::Migration[6.1]
  def change
    rename_column :profiles, :allow_unprompted_dm, :allow_dm
  end
end
