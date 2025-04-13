class CreateBlocks < ActiveRecord::Migration[7.1]
  def change
    create_table :blocks do |t|
      t.references :blocker, null: false, foreign_key: true
      t.references :blocked, null: false, foreign_key: true

      t.timestamps
    end
  end
end
