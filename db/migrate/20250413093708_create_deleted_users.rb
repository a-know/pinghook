class CreateDeletedUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :deleted_users do |t|
      t.string :id
      t.string :username
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
