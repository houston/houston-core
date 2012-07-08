module KanbanHelper
  
  def group_tickets_by_queue_and_project(tickets, projects=nil)
    project_ids = projects ? projects.map(&:id) : tickets.map(&:project_id).uniq
    initial_hash = KanbanQueue.all.each_with_object({}) { |queue, hash| hash[queue.slug] = project_ids.each_with_object({}) { |project_id, hash| hash[project_id] = [] } }
    tickets.each_with_object(initial_hash) { |ticket, hash| hash[ticket.queue][ticket.project_id].push(ticket) }
  end
  
end
