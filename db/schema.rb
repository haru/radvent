# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171211141402) do
  create_table 'advent_calendar_items', force: :cascade do |t|
    t.string 'user_name'
    t.string 'comment'
    t.integer 'date'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.integer 'user_id'
    t.integer 'event_id'
  end

  create_table 'attachments', force: :cascade do |t|
    t.integer 'advent_calendar_item_id'
    t.string 'image'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.index ['advent_calendar_item_id'], name: 'index_attachments_on_advent_calendar_item_id'
  end

  create_table 'comments', force: :cascade do |t|
    t.integer 'item_id'
    t.string 'user_name'
    t.text 'body'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.index ['item_id'], name: 'index_comments_on_item_id'
  end

  create_table 'events', force: :cascade do |t|
    t.string 'title'
    t.string 'name'
    t.integer 'version'
    t.datetime 'updated_at', null: false
    t.datetime 'created_at', null: false
    t.date 'start_date'
    t.date 'end_date'
    t.integer 'created_by_id'
    t.integer 'updated_by_id'
    t.text 'description'
  end

  create_table 'items', force: :cascade do |t|
    t.string 'title'
    t.integer 'advent_calendar_item_id'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.integer 'comments_count', default: 0, null: false
    t.text 'body'
    t.index ['advent_calendar_item_id'], name: 'index_items_on_advent_calendar_item_id', unique: true
  end

  create_table 'likes', force: :cascade do |t|
    t.integer 'item_id'
    t.integer 'user_id'
    t.datetime 'created_at'
    t.datetime 'updated_at'
  end

  create_table 'users', force: :cascade do |t|
    t.string 'email', default: '', null: false
    t.string 'encrypted_password', default: '', null: false
    t.string 'reset_password_token'
    t.datetime 'reset_password_sent_at'
    t.datetime 'remember_created_at'
    t.integer 'sign_in_count', default: 0, null: false
    t.datetime 'current_sign_in_at'
    t.datetime 'last_sign_in_at'
    t.string 'current_sign_in_ip'
    t.string 'last_sign_in_ip'
    t.string 'confirmation_token'
    t.datetime 'confirmed_at'
    t.datetime 'confirmation_sent_at'
    t.string 'unconfirmed_email'
    t.integer 'failed_attempts', default: 0, null: false
    t.string 'unlock_token'
    t.datetime 'locked_at'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'name'
    t.boolean 'admin'
    t.index ['confirmation_token'], name: 'index_users_on_confirmation_token', unique: true
    t.index ['email'], name: 'index_users_on_email', unique: true
    t.index ['reset_password_token'], name: 'index_users_on_reset_password_token', unique: true
    t.index ['unlock_token'], name: 'index_users_on_unlock_token', unique: true
  end
end
