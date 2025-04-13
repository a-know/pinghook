class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users, id: false do |t|
      t.string :id, primary_key: true       # UUIDを自前で使う
      t.string :username, null: false
      t.string :webhook_url, null: false
      t.string :token, null: false

      t.timestamps
    end

    add_index :users, :username, unique: true
    add_index :users, :token, unique: true
  end
end
