class ReplaceEnvironmentIdWithEnvironmentNameDeploys < ActiveRecord::Migration
  RENAMES = {"dev" => "Staging", "master" => "Production"}

  class Environment < ActiveRecord::Base; end

  def up
    add_column :deploys, :environment_name, :string, null: false, default: "Production"
    add_index :deploys, :environment_name
    add_index :deploys, [:project_id, :environment_name]

    Deploy.tap(&:reset_column_information).reorder(nil).each do |deploy|
      if deploy.respond_to?(:environment_id) && (environment = Environment.find_by_id(deploy.environment_id))
        deploy.update_column(:environment_name, environment.name)
      end
    end

    rename_column :user_notifications, :environment, :environment_name
  end

  def down
    remove_column :deploys, :environment_name

    rename_column :user_notifications, :environment_name, :environment
  end
end
