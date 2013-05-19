# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

require 'active_record/fixtures'

path = Rails.root.join("db", "fixtures").to_s
tables = Dir.entries(path).map { |file| file[/^.*(?=\.yml$)/] }.compact

ActiveRecord::Fixtures.create_fixtures(path, tables)
