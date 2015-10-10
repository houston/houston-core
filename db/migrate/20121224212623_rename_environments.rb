class RenameEnvironments < ActiveRecord::Migration
  RENAMES = {
    "dev" => "staging",
    "master" => "production",
    "PRI" => "Staging",
    "Production" => "Production" }

  class Environment < ActiveRecord::Base; end

  def up
    Environment.all.each do |environment|
      environment.slug = RENAMES[environment.slug] ||
        (raise "Didn't anticipate an environment with the slug \"#{environment.slug}\"")
      environment.name = RENAMES[environment.name] ||
        (raise "Didn't anticipate an environment with the name \"#{environment.name}\"")
      environment.save!
    end
  end

  def down
    Environment.all.each do |environment|
      environment.slug = RENAMES.key(environment.slug) ||
        (raise "Didn't anticipate an environment with the slug \"#{environment.slug}\"")
      environment.name = RENAMES.key(environment.name) ||
        (raise "Didn't anticipate an environment with the name \"#{environment.name}\"")
      environment.save!
    end
  end
end
