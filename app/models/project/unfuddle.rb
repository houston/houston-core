class Project < ActiveRecord::Base
  module Unfuddle
    
    def find_tickets(*conditions)
      path = "/projects/#{unfuddle_id}/ticket_reports/dynamic.json"
      params = create_conditions_string(*conditions)
      path << "?#{params}" if params
      get_from_unfuddle(path)
    end
    
    def create_conditions_string(*conditions)
      options = conditions.extract_options!
      conditions.concat(options.map { |key, value|
        if value.is_a?(Array)
          value.map { |val| "#{key}-eq-#{val}" }.join("|")
        else
          "#{key}-eq-#{value}"
        end
      })
      "conditions_string=#{conditions.join("%2C")}"
    end
    
    def get_from_unfuddle(path)
      response = unfuddle.get(path)
      response.body
    end
    
    def unfuddle
      @unfuddle ||= ::Unfuddle.new
    end
    
  end
end
