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

ActiveRecord::Schema[8.1].define(version: 2026_03_01_000000) do
  create_table "advent_calendar_items", force: :cascade do |t|
    t.string "comment"
    t.datetime "created_at", precision: nil
    t.integer "date"
    t.integer "event_id"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.string "user_name"
  end

  create_table "attachments", force: :cascade do |t|
    t.integer "advent_calendar_item_id"
    t.datetime "created_at", precision: nil
    t.string "image"
    t.datetime "updated_at", precision: nil
    t.index ["advent_calendar_item_id"], name: "index_attachments_on_advent_calendar_item_id"
  end

  create_table "comments", id: :integer, default: nil, force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", precision: nil
    t.integer "item_id"
    t.datetime "updated_at", precision: nil
    t.string "user_name"
    t.index ["item_id"], name: "index_comments_on_item_id"
  end

  create_table "events", id: :integer, default: nil, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "created_by_id"
    t.text "description"
    t.date "end_date"
    t.string "name"
    t.date "start_date"
    t.string "title"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "updated_by_id"
    t.integer "version"
    t.index ["name"], name: "index_events_on_name", unique: true
    t.index ["title"], name: "index_events_on_title", unique: true
  end

  create_table "items", id: :integer, default: nil, force: :cascade do |t|
    t.integer "advent_calendar_item_id"
    t.text "body"
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at", precision: nil
    t.string "title"
    t.datetime "updated_at", precision: nil
    t.index ["advent_calendar_item_id"], name: "index_items_on_advent_calendar_item_id", unique: true
  end

  create_table "likes", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "item_id"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin"
    t.datetime "confirmation_sent_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_sign_in_at", precision: nil
    t.string "last_sign_in_ip"
    t.datetime "locked_at", precision: nil
    t.string "name"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end
end
