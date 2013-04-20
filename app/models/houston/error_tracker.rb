Dir["#{Rails.root}/app/models/houston/error_tracker/adapter/*_adapter.rb"].each(&method(:require_dependency))
require_dependency "houston/error_tracker/errors"

module Houston
  
  # Classes in this namespace are assumed to implement
  # Houston's ErrorTracker API.
  # 
  # At this time there are a Null adapter (None) and an adapter for use
  # with Errbit. Adapters for other ticket tracking systems can be added
  # here and will be automatically available to Houston projects.
  #
  module ErrorTracker
    
    def self.adapters
      @adapters ||= 
        Adapter.constants
          .map { |sym| sym[/^.*(?=Adapter)/] }
          .sort_by { |name| name == "None" ? "" : name }
    end
    
    def self.adapter(name)
      Adapter.const_get(name + "Adapter")
    end
    
    def self.arguments
      [:project_id]
    end
    
  end
end
