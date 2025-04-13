# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_04_13_123318) do
  create_table "blocks", force: :cascade do |t|
    t.string "blocker_id", null: false
    t.string "blocked_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blocked_id"], name: "index_blocks_on_blocked_id"
    t.index ["blocker_id", "blocked_id"], name: "index_blocks_on_blocker_id_and_blocked_id", unique: true
    t.index ["blocker_id"], name: "index_blocks_on_blocker_id"
  end

  create_table "deleted_users", id: :string, force: :cascade do |t|
    t.string "username", null: false
    t.datetime "deleted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_deleted_users_on_username"
  end

  create_table "users", id: :string, force: :cascade do |t|
    t.string "username", null: false
    t.string "webhook_url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "token_digest", null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "blocks", "users", column: "blocked_id"
  add_foreign_key "blocks", "users", column: "blocker_id"
end
