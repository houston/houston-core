class AddDeploymentToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :deployment, :string
  end
end
