require 'unfuddle/neq'

class KanbanQueue
  
  attr_accessor :name, :slug, :description
  
  def initialize(attributes={})
    @name = attributes[:name]
    @slug = attributes[:slug]
    @description = attributes[:description]
    @where = attributes[:where]
  end
  
  def filter(tickets)
    @where.call(tickets)
  end
  
  class << self
    def all
      @queues ||= create(Houston.config.queues)
    end
    
    def slugs
      @slugs ||= all.map(&:slug)
    end
    
    def find_by_slug(slug)
      all.find { |queue| queue.slug == slug }
    end
    
    def create(*attributes_array)
      attributes_array.flatten.map { |attributes| KanbanQueue.new(attributes) }
    end
  end
  
  slugs.each do |slug|
    class_eval <<-RUBY
    def #{slug.downcase}?
      slug == "#{slug}"
    end
    RUBY
  end
  
  
end
