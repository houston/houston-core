class AddAntecedentsToTickets < ActiveRecord::Migration
  def up
    add_column :tickets, :antecedents, :string, array: true

    Ticket.reset_column_information

    Ticket.unscoped.find_each do |ticket|
      goldmine_numbers = ticket.goldmine || ""

      antecedents = []
      antecedents.concat goldmine_numbers.split(/[, ]/).map(&:strip).reject(&:blank?).map { |number| "Goldmine:#{number}" }
      antecedents.concat ticket.description.to_s.scan(/^Goldmine: (\d+)/).flatten.map { |number| "Goldmine:#{number}" }
      antecedents.concat ticket.description.to_s.scan(/^Errbit: ([0-9a-fA-F]+)/).flatten.map { |number| "Errbit:#{number}" }

      next if antecedents.empty?

      puts "#{ticket.id}: #{antecedents.join(", ")}"
      ticket.antecedents = antecedents
      ticket.save!(validate: false)
    end
  end

  def down
    remove_column :tickets, :antecedents
  end
end
