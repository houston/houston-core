class ReplaceMilestonesExtendedAttributesWithProps < ActiveRecord::Migration[5.0]
  def up
    remove_column :milestones, :extended_attributes
    add_column :milestones, :props, :jsonb, default: {}
  end

  def down
    remove_column :milestones, :props
    add_column :milestones, :extended_attributes, :hstore
  end
end
