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

ActiveRecord::Schema.define(:version => 20121224212623) do

  create_table "changes", :force => true do |t|
    t.integer  "release_id"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "tag_slug"
  end

  create_table "commits", :force => true do |t|
    t.integer  "release_id"
    t.string   "sha"
    t.text     "message"
    t.string   "committer"
    t.date     "date"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.string   "committer_email"
  end

  create_table "commits_tickets", :id => false, :force => true do |t|
    t.integer "commit_id"
    t.integer "ticket_id"
  end

  add_index "commits_tickets", ["commit_id", "ticket_id"], :name => "index_commits_tickets_on_commit_id_and_ticket_id", :unique => true

  create_table "deploys", :force => true do |t|
    t.integer  "project_id"
    t.integer  "environment_id"
    t.string   "commit"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
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
    t.integer  "ticket_tracking_id"
    t.string   "version_control_location"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.string   "color"
    t.text     "cached_queries"
    t.string   "errbit_app_id"
    t.integer  "new_relic_id"
    t.datetime "retired_at"
    t.string   "category"
    t.string   "version_control_adapter",  :default => "None", :null => false
    t.string   "ticket_tracking_adapter",  :default => "None", :null => false
  end

  create_table "projects_maintainers", :id => false, :force => true do |t|
    t.integer "project_id"
    t.integer "user_id"
  end

  add_index "projects_maintainers", ["project_id", "user_id"], :name => "index_projects_maintainers_on_project_id_and_user_id", :unique => true

  create_table "releases", :force => true do |t|
    t.integer  "environment_id"
    t.string   "name"
    t.string   "commit0"
    t.string   "commit1"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.integer  "user_id",                        :null => false
    t.text     "message",        :default => "", :null => false
    t.integer  "deploy_id"
  end

  add_index "releases", ["deploy_id"], :name => "index_releases_on_deploy_id"

  create_table "releases_tickets", :id => false, :force => true do |t|
    t.integer "release_id"
    t.integer "ticket_id"
  end

  add_index "releases_tickets", ["release_id", "ticket_id"], :name => "index_releases_tickets_on_release_id_and_ticket_id", :unique => true

  create_table "testing_notes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "ticket_id"
    t.string   "verdict",                     :null => false
    t.text     "comment",     :default => "", :null => false
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
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
    t.integer  "unfuddle_id"
    t.string   "deployment"
    t.datetime "last_release_at"
    t.string   "goldmine"
    t.decimal  "estimated_effort", :precision => 9,  :scale => 2
    t.decimal  "estimated_value",  :precision => 11, :scale => 2
    t.datetime "expires_at"
  end

  create_table "user_notifications", :force => true do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.string   "environment"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
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
    t.string   "authentication_token"
    t.boolean  "administrator",                        :default => false
    t.integer  "unfuddle_id"
    t.string   "first_name"
    t.string   "last_name"
  end

  add_index "users", ["authentication_token"], :name => "index_users_on_authentication_token"
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["invitation_token"], :name => "index_users_on_invitation_token"
  add_index "users", ["invited_by_id"], :name => "index_users_on_invited_by_id"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
