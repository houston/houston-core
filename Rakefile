#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

# When `rake test` is run with `ci:setup:minitest`, this will cause the CI::Reporter formatter
# to replace the Turn formatter for the test runner. Without `ci:setup:minitest`, this line
# has no effect. (I think.)
require "ci/reporter/rake/minitest"

Houston::Application.load_tasks

# db/structure.sql is always written out after db:migrate is run.
# It be checked into the repo and always used to create the database
# structure in test environment.
#
# On a CI server, there _is_ no environment other than the test
# environment; but db:test:clone_structure tries to dump the schema
# of the current environment before loading it. In a test environment,
# this would be circular and useless.
#
# db:test:clone_structure is defined this way:
#   task :clone_structure => [ "db:structure:dump", "db:test:load_structure" ]
#
# c.f. https://github.com/rails/rails/blob/v3.2.8/activerecord/lib/active_record/railties/databases.rake#L486
#
# What this line does is to remove the db:structure:dump prerequisite.
Rake::Task["db:test:clone_structure"].prerequisites.shift
