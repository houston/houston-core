class KanbanQueue
  
  attr_accessor :name, :slug, :description
  
  def initialize(attributes={})
    @name = attributes[:name]
    @slug = attributes[:slug]
    @description = attributes[:description]
  end
  
  class << self
    def all
      @queues ||= create [
        { name: "On Deck",
          slug: "staged_for_development",
          description: "Tickets staged for development" },
        { name: "In Development",
          slug: "in_development",
          description: "Tickets currently being worked on" },
        { name: "On Deck",
          slug: "staged_for_testing",
          description: "Tickets waiting to enter testing" },
        { name: "In Testing",
          slug: "in_testing",
          description: "Tickets ready to test" },
        { name: "On Deck",
          slug: "staged_for_release",
          description: "Tickets staged for the next release" },
        { name: "Last Release",
          slug: "last_release",
          description: "Tickets closed during the last release" }
      ]
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
  
end
