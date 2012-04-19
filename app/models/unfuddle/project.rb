class Unfuddle
  class Project
    
    
    
    def initialize(unfuddle, project_id)
      @unfuddle = unfuddle
      @project_id = project_id
    end
    
    attr_reader :unfuddle, :project_id
    
    
    
    def find_tickets(*conditions)
      path = "/projects/#{project_id}/ticket_reports/dynamic.json"
      params = create_conditions_string(*conditions)
      path << "?#{params}" if params
      parse_ticket_report get_from_unfuddle(path)
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
      Rails.logger.info "[unfuddle] #{path}"
      response = unfuddle.get(path)
      response.body
    end
    
    def parse_ticket_report(json)
      ticket_report = parse_response(json)
      group0 = ticket_report.fetch("groups", [])[0] || {}
      group0.fetch("tickets", [])
    end
    
    def parse_response(json)
      JSON.load(json)
    end
    
    
    
  end
end
