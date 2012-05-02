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

ActiveRecord::Schema.define(:version => 20120501231948) do

  create_table "changes", :force => true do |t|
    t.integer  "release_id"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "commits", :force => true do |t|
    t.integer  "release_id"
    t.string   "sha"
    t.text     "message"
    t.string   "committer"
    t.date     "date"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "environments", :force => true do |t|
    t.string   "slug"
    t.string   "name"
    t.integer  "project_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.string   "initial_commit"
  end

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.string   "slug"
    t.integer  "unfuddle_id"
    t.string   "git_url"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.string   "color"
    t.string   "kanban_field"
    t.integer  "development_id"
    t.integer  "testing_id"
    t.integer  "production_id"
  end

  create_table "releases", :force => true do |t|
    t.integer  "environment_id"
    t.string   "name"
    t.string   "commit0"
    t.string   "commit1"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "testing_notes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "ticket_id"
    t.string   "verdict",                     :null => false
    t.string   "comment",     :default => "", :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.datetime "expires_at"
    t.integer  "unfuddle_id"
  end

  add_index "testing_notes", ["ticket_id"], :name => "index_testing_notes_on_ticket_id"
  add_index "testing_notes", ["user_id"], :name => "index_testing_notes_on_user_id"

  create_table "ticket_queues", :force => true do |t|
    t.integer  "ticket_id"
    t.string   "queue"
    t.datetime "destroyed_at"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "tickets", :force => true do |t|
    t.integer  "project_id"
    t.integer  "number"
    t.string   "summary"
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.integer  "unfuddle_id"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email",                                :default => "",          :null => false
    t.string   "encrypted_password",                   :default => ""
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                        :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                                    :null => false
    t.datetime "updated_at",                                                    :null => false
    t.string   "invitation_token",       :limit => 60
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.string   "role",                                 :default => "Developer"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["invitation_token"], :name => "index_users_on_invitation_token"
  add_index "users", ["invited_by_id"], :name => "index_users_on_invited_by_id"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
