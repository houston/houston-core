module Gemnasium
  class Alert
    
    def self.all
      connection = Faraday.new(url: "https://api.gemnasium.com/v1/")
      connection.basic_auth "X", Houston.config.gemnasium[:api_key]
      
      response = connection.get "projects"
      unless response.status == 200
        Rails.logger.error "\e[31m GET /projects responded with #{response.status}\e[0m"
        return
      end
      
      projects = JSON.load(response.body).values.flatten
      
      projects.parallel.map do |project|
        response = connection.get "projects/#{project["slug"]}/alerts"
        Array(JSON.load(response.body)).map { |alert| alert.merge(
          "project_id" => project["slug"],
          "project_slug" => project["name"]) }
      end.flatten
    end
    
    def self.open
      all.select { |alert| alert["status"] != "closed" }
    end
    
  end
end
