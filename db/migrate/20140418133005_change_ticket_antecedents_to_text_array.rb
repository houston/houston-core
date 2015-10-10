class ChangeTicketAntecedentsToTextArray < ActiveRecord::Migration
  def up
    change_column :tickets, :antecedents, :text, array: true
  end

  def down
    change_column :tickets, :antecedents, :string, array: true
  end
end
