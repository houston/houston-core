class AddTriggerAndParamsToActions < ActiveRecord::Migration
  def change
    add_column :actions, :trigger, :string
    add_column :actions, :params, :text
  end
end
