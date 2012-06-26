set :application, "changelog"
load File.expand_path("~/epic.cap")

set :repository, "git://github.com/boblail/changelog.git"
set :branch, "master"

before "bundler:install", "deploy:symlink_config"
after "deploy:update_code", "deploy:compile_assets"

namespace :deploy do
  
  task :compile_assets, :roles => :app do
    rake "assets:precompile"
  end
  
  task :symlink_config, :roles => :app do
    run "ln -nfs #{shared_path}/config/config.rb #{release_path}/config/config.rb"
    run "rm -rf #{release_path}/tmp"
    run "ln -nfs #{shared_path}/tmp #{release_path}"
  end
  
end
