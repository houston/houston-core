class CreateDeploys < ActiveRecord::Migration
  def change
    create_table :deploys do |t|
      t.references :project
      t.references :environment
      t.string :commit

      t.timestamps
    end
  end
end
