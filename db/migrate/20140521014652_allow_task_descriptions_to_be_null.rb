class AllowTaskDescriptionsToBeNull < ActiveRecord::Migration
  def up
    change_column_null :tasks, :description, true
    Task.where(number: 1).update_all(description: nil)
  end

  def down
    Task.where(description: nil).includes(:ticket).find_each do |task|
      task.update_column :description, task.ticket.summary
    end
    change_column_null :tasks, :description, false
  end
end
