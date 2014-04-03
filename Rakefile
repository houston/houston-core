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
# db:test:clone_structure is defined this way:
#   task :clone_structure => [ "db:structure:dump", "db:test:load_structure" ]
#
# c.f. https://github.com/rails/rails/blob/v3.2.8/activerecord/lib/active_record/railties/databases.rake#L486
#
# What this line does is to remove the db:structure:dump prerequisite.
Rake::Task["db:test:clone_structure"].prerequisites.shift

# I _believe_ that db:test:load_structure will put the test database's
# schema into a predictable state. Since the CI environment relies on this
# and NOT on migrations, there's no reason to check if there are any
# pending migrations, especially BEFORE running load_structure!
#
# db:test:prepare is defined this way:
#   task :prepare => 'db:abort_if_pending_migrations' . . .
#
# c.f. https://github.com/rails/rails/blob/v3.2.8/activerecord/lib/active_record/railties/databases.rake#L522
#
# This feature _is_ useful in a development environment, so let's remove
# it only when running on a CI server. NOTE! db:abort_if_pending_migrations
# has an important side-effect: it loads Rails's environment :). We still
# want to do that.
if ENV["CI"] == "true"
  db_test_prepare_task = Rake::Task["db:test:prepare"]
  db_test_prepare_task.prerequisites.shift
  db_test_prepare_task.prerequisites.push :environment
  db_test_prepare_task.prerequisites.push :load_config
end
