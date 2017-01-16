class CreateHistoricalHeads < ActiveRecord::Migration
  def up
    create_table :historical_heads do |t|
      t.integer :project_id, null: false
      t.hstore :branches, null: false, default: {}

      t.timestamps
    end

    Project.unretired.where("projects.version_control_name != 'None'").each do |project|
      puts "Checking #{project.slug}"
      project.repo.refresh!

      HistoricalHead.create!(
        project_id: project.id,
        branches: project.repo.branches)
    end
  end

  def down
    drop_table :historical_heads
  end
end
