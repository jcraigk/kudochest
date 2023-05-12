class CreateChannels < ActiveRecord::Migration[6.0]
  def change
    create_table :channels do |t|
      t.references :team
      t.string :rid, null: false
      t.string :name, null: false
      t.boolean :shared, null: false
      t.timestamps
    end

    add_index :channels, %i[rid team_id], unique: true
    add_index :channels, %i[name team_id], unique: true
  end
end
