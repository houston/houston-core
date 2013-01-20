class TicketPrerequisite < ActiveRecord::Base
  
  belongs_to :ticket
  
  def self.not_numbered(*numbers)
    numbers = numbers.flatten
    return scoped if numbers.empty?
    where arel_table[:prerequisite_ticket_number].not_in(numbers)
  end
  
end
