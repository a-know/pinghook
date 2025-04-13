class RenameTokenToTokenDigest < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :token, :string
    add_column :users, :token_digest, :string, null: false
  end
end