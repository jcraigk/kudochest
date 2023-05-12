class CreateSubteams < ActiveRecord::Migration[6.0]
  def change
    create_table :subteams do |t|
      t.references :team
      t.string :rid, null: false
      t.string :name, null: false
      t.string :description, null: false
      t.string :handle, null: false
      t.timestamps
    end

    add_index :subteams, %i[rid team_id], unique: true
    add_index :subteams, :name
    add_index :subteams, :handle
  end
end
