class CreateDeletedUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :deleted_users, id: false do |t|
      t.string :id, primary_key: true
      t.string :username, null: false
      t.datetime :deleted_at, null: false

      t.timestamps
    end

    add_index :deleted_users, :username
  end
end
