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
        { name: "Assign Health",
          slug: "assign_health",
          description: "New tickets to be screened" },
        { name: "New Tickets",
          slug: "new_tickets",
          description: "New tickets to be accepted" },
        { name: "On Deck",
          slug: "staged_for_development",
          description: "Tickets staged for development" },
        { name: "In Development",
          slug: "in_development",
          description: "Tickets currently being worked on" },
        { name: "On Deck",
          slug: "staged_for_testing",
          description: "Tickets waiting to enter testing" },
        { name: "In Testing (PRI)",
          slug: "in_testing",
          description: "Tickets ready to test in PRI" },
        { name: "In Testing (Production)",
          slug: "in_testing_production",
          description: "Tickets ready to test in Production" }
        # { name: "Ready to Release",
        #   slug: "staged_for_release",
        #   description: "Tickets staged for the next release" }
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
  
  slugs.each do |slug|
    class_eval <<-RUBY
    def #{slug.downcase}?
      slug == "#{slug}"
    end
    RUBY
  end
  
  
end
