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
        { name: "To Proofread",
          slug: "assign_health",
          description: "<b>Testers</b>, check that these tickets are healthy and unique." },
        { name: "To Accept",
          slug: "new_tickets",
          description: "<b>Developers</b>, check that these tickets make sense and accept them." },
        { name: "Flagged",
          slug: "staged_for_development",
          description: "Tickets flagged for forthcoming work" },
        { name: "In Development",
          slug: "in_development",
          description: "Tickets currently being worked on" },
        { name: "Queued",
          slug: "staged_for_testing",
          description: "Tickets waiting to enter testing" },
        { name: "In Testing (PRI)",
          slug: "in_testing",
          description: "<b>Testers</b>, these tickets are ready to test <u>in PRI</u>" },
        { name: "In Testing (Production)",
          slug: "in_testing_production",
          description: "<b>Testers</b>, these tickets are ready to test <u>in Production</u>" }
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
