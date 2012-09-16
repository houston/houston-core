class UnfuddleDump
  
  class << self
    
    def path
      @path ||= Rails.root.join("tmp", "unfuddle_tickets.json")
    end
    
    def exists?
      File.exists?(path)
    end
    
    def delete!
      File.delete(path)
    end
    
    def last_updated
      File.mtime(path) if exists?
    end
    
    def last_updated_time
      exists? ? File.mtime(path).to_f : 0.0
    end
    
    def age
      (Time.now.to_f - last_updated_time).seconds
    end
    
    def fresh?
      age < 1.day
    end
    
    def fetch!
      requested_fields = %w{created_at closed_on severity}
      picked_fields = %w{created_at closed_on severity_id id number project_id}
      
      url = "ticket_reports/dynamic.json?fields_string=#{requested_fields.join(",")}"
      response = Unfuddle.get(url)
      
      binding.pry unless response[0].to_i == 200
      report = response[1]
      group0 = report.fetch("groups", [])[0] || {}
      tickets = group0.fetch("tickets", [])
      tickets.map { |ticket| ticket.pick(picked_fields) }
    end
    
    def download!
      fetch!.tap do |tickets|
        File.open(path, "w") do |f|
          f.write(JSON.dump(tickets))
        end
      end
    end
    
    def load!
      fresh? ? read : download!
    end
    
    def read
      JSON.load File.read(path)
    end
    
  end
  
end
