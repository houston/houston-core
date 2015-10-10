require 'ostruct'

class Antecedent

  def initialize(attributes={})
    @ticket = attributes.fetch(:ticket, Ticket.first)
    @reporter = attributes.fetch(:reporter, User.first)
    @created_at = attributes.fetch(:created_at, 1.week.ago)
    @customer = attributes.fetch(:customer, OpenStruct.new(name: "Humphrey Blaughfellow"))
    @notes = attributes.fetch(:notes, "Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo volupt")
  end

  attr_reader :ticket, :reporter, :created_at, :customer, :notes

end
