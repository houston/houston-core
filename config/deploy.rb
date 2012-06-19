set :application, "changelog"
load File.expand_path("~/epic.cap")

set :repository, "git://github.com/boblail/changelog.git"
set :branch, "master"

after "deploy:update_code", "deploy:compile_assets"
after "deploy:copy_database_yml", "deploy:symlink_config"

namespace :deploy do
  
  task :compile_assets, :roles => :app do
    rake "assets:precompile"
  end
  
  task :symlink_config, :roles => :app do
    run "ln -nfs #{shared_path}/config/config.rb #{release_path}/config/config.rb"
  end
  
end
