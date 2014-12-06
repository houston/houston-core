set :application, "houston"
load File.expand_path("~/epic.cap")

set :repository, "git://github.com/houstonmc/houston.git"

before "bundler:install", "deploy:symlink_config"
after "deploy:setup", "deploy:copy_config_rb"
after "deploy:setup", "deploy:create_shared_folders"

namespace :deploy do
  
  task :symlink_config, :roles => :app do
    commands = [
      "ln -nfs #{shared_path}/config/config.rb #{release_path}/config/config.rb",
      "ln -nfs #{shared_path}/config/skylight.yml #{release_path}/config/skylight.yml",
      "ln -nfs #{shared_path}/config/keypair.pem #{release_path}/config/keypair.pem",
      "rm -f #{release_path}/config/secrets.yml",
      "ln -nfs #{shared_path}/config/secrets.yml #{release_path}/config/secrets.yml",
      "rm -rf #{release_path}/tmp",
      "ln -nfs #{shared_path}/tmp #{release_path}",
      "ln -nfs #{shared_path}/extras #{release_path}/public/extras",
    ]
    run commands.join(" && ")
  end
  
  desc "Copy config.rb"
  task :copy_config_rb, :roles => :app do
    run "mkdir -p #{shared_path}/config"
    put(File.read(File.join(Dir.pwd, "config/config.rb")), "#{shared_path}/config/config.rb")
  end
  
  desc "Create other shared folders"
  task :create_shared_folders, :roles => :app do
    run "mkdir -p #{shared_path}/tmp"
  end
  
end
