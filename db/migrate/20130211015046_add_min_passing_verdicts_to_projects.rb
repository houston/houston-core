class AddMinPassingVerdictsToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :min_passing_verdicts, :integer, :null => false, :default => 1
  end
end
