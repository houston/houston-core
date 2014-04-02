class TicketQueue < ActiveRecord::Base
  
  belongs_to :ticket
  
  validates :ticket, :presence => true
  validates :queue, :presence => true, :inclusion => KanbanQueue.slugs
  
  default_scope joins(:ticket)
  
  
  
  class << self
    def for_kanban
      where(queue: KanbanQueue.slugs)
    end
    
    def in_queue(queue)
      queue = queue.slug if queue.is_a?(KanbanQueue)
      where(queue: queue)
    end
    alias :named :in_queue
    
    def for_project(project)
      where(["tickets.project_id = ?", project.id])
    end
    
    def during(date_or_range)
      range = date_or_range..date_or_range unless date_or_range.is_a?(Range)
      where("ticket_queues.created_at <= ? AND (ticket_queues.destroyed_at IS NULL OR ticket_queues.destroyed_at >= ?)", range.end, range.begin)
    end
    alias :on :during
    alias :at :during
    
    
    
    def enter!(slug, ids)
      return if ids.none?
      in_queue(slug).create! ids.map { |id| { ticket_id: id } }
    end
    
    def exit!(slug, ids)
      return if ids.none?
      in_queue(slug).where(ticket_id: ids).exit_all!
    end
    
    
    
    def exit_all!
      update_all(destroyed_at: Time.now)
    end
    
    
    
    def average_time_for_queue(queue)
      queue = queue.slug if queue.is_a?(KanbanQueue)
      
      connection.select_value "SELECT AVG(q.time_in_queue) FROM (#{where(queue: queue).with_time_in_queue.to_sql}) AS q"
    end
    
    def average_time_for_queues
      hashes = connection.select_all "SELECT q.queue, AVG(q.time_in_queue) FROM (#{with_time_in_queue.to_sql}) AS q GROUP BY q.queue"
      Hash[hashes.map(&:values)]
    end
    
    def with_time_in_queue
      where("ticket_queues.destroyed_at IS NOT NULL") \
        .group("queue, ticket_id") \
        .select("queue, ticket_id, SUM(EXTRACT(EPOCH FROM (ticket_queues.destroyed_at-ticket_queues.created_at))) AS time_in_queue")
    end
    
    
    
    def average_time_for_queues_for_project(project)
      hashes = connection.select_all "SELECT q.queue, AVG(q.time_in_queue) FROM (#{with_time_in_queue_for_project(project).to_sql}) AS q GROUP BY q.queue"
      Hash[hashes.map(&:values)]
    end
    
    def with_time_in_queue_for_project(project)
      where("ticket_queues.destroyed_at IS NOT NULL") \
        .joins("INNER JOIN tickets ON ticket_queues.ticket_id=tickets.id") \
        .where("tickets.project_id=#{project.id}") \
        .group("queue, ticket_id") \
        .select("queue, ticket_id, SUM(EXTRACT(EPOCH FROM (ticket_queues.destroyed_at-ticket_queues.created_at))) AS time_in_queue")
    end
  end
  
  
  def name
    queue
  end
  
  def destroy
    run_callbacks(:destroy) { delete }
  end
  
  def delete
    return if deleted? or new_record?
    update_column :destroyed_at, Time.now
  end
  
  def destroyed?
    !self.destroyed_at.nil?
  end
  alias :deleted? :destroyed?
  
  # Returns the amount of time the ticket spent in the given queue (in seconds)
  def queue_time
    end_time = destroyed? ? destroyed_at : Time.now
    end_time - created_at
  end
  
end
