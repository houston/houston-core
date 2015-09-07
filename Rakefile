# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)


Houston::Application.load_tasks

# gemoji
load 'tasks/emoji.rake'

# db/structure.sql is always written out after db:migrate is run.
# It be checked into the repo and always used to create the database
# structure in test environment.
#
# On a CI server, there _is_ no environment other than the test
# environment; but db:test:clone_structure tries to dump the schema
# of the current environment before loading it. In a test environment,
# this would be circular and useless.
#
# What this line does is to remove the db:structure:dump prerequisite.
Rake::Task["db:test:clone_structure"].prerequisites.delete "db:structure:dump"
