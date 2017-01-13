class DropTicketsAntecedents < ActiveRecord::Migration[5.0]
  def up
    remove_column :tickets, :antecedents
  end

  def down
    add_column :tickets, :antecedents, :text, array: true
  end
end
