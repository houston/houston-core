class UnfuddleTicketDownloadJob
  
  
  def self.download!
    self.new.download!
  end
  
  
  def download!
    fetch!.tap do |tickets|
      puts "writing to \"#{UnfuddleDump.path}\""
      File.open(UnfuddleDump.path, "w") do |f|
        f.write(JSON.dump(tickets))
      end
    end
  end
  
  def fetch!
    requested_fields = %w{created_at closed_on severity reporter}
    
    url = "ticket_reports/dynamic.json?fields_string=#{requested_fields.join(",")}&exclude_description=true"
    response = Unfuddle.get(url)
    
    binding.pry unless response.status == 200
    report = response.json
    group0 = report.fetch("groups", [])[0] || {}
    tickets = group0.fetch("tickets", [])
    
    process_tickets(tickets)
  end
  
  def process_tickets(tickets)
    projects = Hash.new { |hash, id| hash[id] = Unfuddle.instance.project(id) }
    picked_fields = %w{created_at closed_on id number project_id resolution status reporter_id}
    
    tickets.map do |all_values|
      ticket = all_values.pick(picked_fields)
      project = projects[ticket["project_id"]]
      
      if project.custom_field_defined?("Health")
        health_id = all_values[project.get_ticket_attribute_for_custom_value_named!("Health")]
        ticket["health"] = project.find_custom_field_value_by_id!("Health", health_id).value unless health_id.blank?
      end
      
      severity_id = all_values["severity_id"]
      severity = project.severities.find { |severity| severity.id == severity_id }
      ticket["severity"] = severity && severity.name
      
      ticket
    end
  end
  
  
end
