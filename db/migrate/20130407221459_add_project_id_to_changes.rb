class AddProjectIdToChanges < ActiveRecord::Migration
  def up
    add_column :changes, :project_id, :integer
    
    Change.reset_column_information
    Change.find_each do |change|
      release = change.release
      
      if release.nil?
        change.delete
        Rails.logger.warn "Deleting change ##{change.id} (#{change.attributes.inspect})"
        next
      end
      
      change.update_column(:project_id, release.project_id)
    end
    
    change_column_null :changes, :project_id, false
    
    add_index :changes, [:project_id]
  end
  
  def down
    remove_column :changes, :project_id
  end
end
