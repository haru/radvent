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

ActiveRecord::Schema[8.0].define(version: 2017_12_11_141402) do
  create_table "advent_calendar_items", force: :cascade do |t|
    t.string "user_name"
    t.string "comment"
    t.integer "date"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.integer "event_id"
  end

  create_table "attachments", force: :cascade do |t|
    t.integer "advent_calendar_item_id"
    t.string "image"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["advent_calendar_item_id"], name: "index_attachments_on_advent_calendar_item_id"
  end

  create_table "comments", force: :cascade do |t|
    t.integer "item_id"
    t.string "user_name"
    t.text "body"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["item_id"], name: "index_comments_on_item_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "title"
    t.string "name"
    t.integer "version"
    t.date "start_date"
    t.date "end_date"
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "description"
  end

  create_table "items", force: :cascade do |t|
    t.string "title"
    t.integer "advent_calendar_item_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "comments_count", default: 0, null: false
    t.text "body"
    t.index ["advent_calendar_item_id"], name: "index_items_on_advent_calendar_item_id", unique: true
  end

  create_table "likes", force: :cascade do |t|
    t.integer "item_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.boolean "admin"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end
end
