module KanbanHelper
  
  def group_tickets_by_queue_and_project(tickets, projects)
    projects_by_id = projects.index_by(&:id)
    
    KanbanQueue.all.each_with_object({}) do |queue, tickets_by_queue|
      tickets_in_queue = projects_by_id.keys.each_with_object({}) { |project_id, hash| hash[project_id] = [] }
      queue.filter(tickets).each do |ticket|
        tickets_in_queue[ticket.project_id].push(ticket)
      end
      tickets_by_queue[queue.slug] = tickets_in_queue
    end
  end
  
end
