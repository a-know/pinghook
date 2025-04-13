class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :username
      t.string :webhook_url
      t.string :token

      t.timestamps
    end
  end
end
