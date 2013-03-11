class UpdateKanbanQueueJob
  
  
  def self.run!
    new.run!
  end
  
  def run!
    next_query!
  end
  
  def next_query!
    request = next_request!
    return unless request
    
    project, queue = request
    begin
      project.tickets_in_queue(queue)
    rescue
      Houston.report_exception($!)
    ensure
      sleep 2 # give Unfuddle a break
      next_query!
    end
  end
  
  def next_request!
    requests.pop
  end
  
  
private
  
  
  def initialize
    setup_requests!
  end
  
  def setup_requests!
    projects = Project.with_ticket_tracking.to_a
    queues = KanbanQueue.all
    @requests = projects.product(queues)
  end
  
  attr_reader :requests
  
  
end
