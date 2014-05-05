# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 14) do

  create_table "account_categories", :force => true do |t|
    t.integer "account_id"
    t.integer "category_id"
  end

  create_table "accounts", :force => true do |t|
    t.integer "user_id"
    t.string  "name"
    t.string  "url"
    t.string  "username"
    t.string  "password"
    t.string  "acct_number"
    t.integer "due_on"
    t.string  "notes"
  end

  create_table "categories", :force => true do |t|
    t.integer "user_id"
    t.integer "category_id"
    t.string  "name"
  end

  create_table "contact_categories", :force => true do |t|
    t.integer "contact_id"
    t.integer "category_id"
  end

  create_table "contacts", :force => true do |t|
    t.integer "user_id"
    t.string  "home_phone"
    t.string  "cell_phone"
    t.string  "work_phone"
    t.string  "email"
    t.string  "website"
    t.string  "address"
    t.string  "first_name"
    t.string  "last_name"
  end

  create_table "note_categories", :force => true do |t|
    t.integer "note_id"
    t.integer "category_id"
  end

  create_table "notes", :force => true do |t|
    t.integer  "user_id"
    t.string   "subject"
    t.text     "note"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "task_categories", :force => true do |t|
    t.integer "task_id"
    t.integer "category_id"
  end

  create_table "tasks", :force => true do |t|
    t.integer "user_id"
    t.integer "task_id"
    t.string  "name"
  end

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "email"
    t.string   "password_hash"
    t.string   "password_salt"
    t.string   "password_reset_token"
    t.datetime "password_expires_after"
    t.string   "authentication_token"
    t.datetime "last_signed_in_on"
    t.datetime "signed_up_on"
    t.boolean  "is_admin"
  end

end
