set :application, "changelog"
load File.expand_path("~/epic.cap")

set :repository, "git://github.com/boblail/changelog.git"
set :branch, "master"

after "deploy:update_code", "deploy:compile_assets"

namespace :deploy do
  
  task :compile_assets, :roles => :app do
    rake "assets:precompile"
  end
  
end
