class RemoveSubscribeNewsletterFromUsers < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :subscribe_newsletter, :boolean, null: false
  end
end
