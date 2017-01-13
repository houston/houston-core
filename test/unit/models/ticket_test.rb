require "test_helper"


class TicketTest < ActiveSupport::TestCase
  attr_reader :project, :ticket

  setup do
    Ticket.nosync = true
    @project = create(:project)
  end



  context "#reopen!" do
    setup do
      @ticket = Ticket.create!(
        project: project,
        number: 1,
        summary: "Test summary",
        resolution: "fixed",
        type: "Bug")
    end

    context "an unresolved ticket" do
      setup do
        ticket.update_column :resolution, ""
      end

      should "do nothing" do
        mock(ticket).remote_ticket.never
        mock(ticket).update_attributes.never

        ticket.reopen!
      end
    end

    should "send #reopen! to #remote_ticket" do
      remote_ticket = Object.new.tap do |remote_ticket|
        mock(remote_ticket).reopen! { }
      end
      mock(ticket).remote_ticket { remote_ticket }.at_least(1)

      ticket.reopen!
    end

    should "touch the reopened_at timestamp" do
      Timecop.freeze Time.zone.now do
        ticket.reopen!
        assert_equal Time.zone.now, ticket.reopened_at
      end
    end
  end



  context "#tags" do
    setup do
      @ticket = create(:ticket, project: project)
    end

    should "accept an array of strings" do
      ticket.tags = ["Bug", "No Work-Around"]
      assert_equal 2, ticket.tags.length
      assert_equal TicketTag, ticket.tags.first.class
      assert_equal ["Bug", "No Work-Around"], ticket.tags.map(&:name)
    end

    should "accept an array of TicketTag objects" do
      ticket.tags = [TicketTag.new("Bug", "b50000")]
      assert_equal 1, ticket.tags.length
      assert_equal TicketTag, ticket.tags.first.class
      assert_equal "Bug", ticket.tags.first.name
      assert_equal "b50000", ticket.tags.first.color
    end
  end



  context "Houston.config.parse_ticket_description" do
    should "be invoked when creating a ticket" do
      ticket = Ticket.new default_ticket_attributes.merge(description: "Original description")
      mock(Houston.config).parse_ticket_description(ticket)
      ticket.save!
    end

    should "be invoked when updating a ticket's description" do
      ticket = Ticket.create! default_ticket_attributes
      mock(Houston.config).parse_ticket_description(ticket)
      ticket.update_attributes(description: "New description")
    end
  end



  context "Tasks:" do
    context "a new ticket with no tasks defined" do
      setup do
        @ticket = Ticket.new default_ticket_attributes
      end

      should "implicitly create a task with the same description as the ticket" do
        ticket.save!
        assert_equal 1, ticket.tasks.count, task_wasnt_created(ticket)
        assert_equal ticket.summary, ticket.tasks.first.description,
          "Expected the default tasks' description to match the ticket's summary"
      end
    end

    context "a ticket" do
      should "be invalid if it has no tasks" do
        ticket = Ticket.new default_ticket_attributes
        stub(ticket).ensure_that_ticket_has_a_task # prevent ticket from creating a task
        refute ticket.valid?, "Expected a ticket without a task to be invalid"
        assert_match /must have at least one task/, ticket.errors.full_messages.join,
          "Expected the ticket to report that it must have a task"
      end
    end
  end



  context "#effort" do
    setup do
      @ticket = Ticket.new default_ticket_attributes
    end

    should "report the sum of its tasks effort" do
      @ticket.tasks.build(description: "1", effort: 5)
      @ticket.tasks.build(description: "2", effort: 1)
      @ticket.tasks.build(description: "3", effort: 12)
      assert_equal 18, @ticket.effort
    end
  end



private

  def default_ticket_attributes
    { project: project,
      type: "Bug",
      number: 1,
      summary: "Test summary" }
  end

  def task_wasnt_created(ticket)
    if ticket.tasks.length == 0
      "Expected the ticket to have implicitly create its only task"
    else
      "Expected the implicitly-created task to be valid, but #{ticket.tasks.first.errors.full_messages.join(", ")}"
    end
  end

end
