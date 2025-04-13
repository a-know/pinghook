class AddLastSentAtToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :last_sent_at, :datetime
  end
end
