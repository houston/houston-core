module Gemnasium
  class Alert
    
    def self.all
      connection = Faraday.new(url: "https://api.gemnasium.com/v1/")
      connection.basic_auth "X", Houston.config.gemnasium[:api_key]
      
      response = connection.get "projects"
      unless response.status == 200
        Rails.logger.warn "\e[31m[gemnasium] \e[1mGET /projects\e[0;31m responded with #{response.status}\e[0m"
        return
      end
      
      projects = JSON.load(response.body).values.flatten
      
      projects.parallel.map do |project|
        path = "projects/#{project["slug"]}/alerts"
        response = connection.get path
        unless response.status == 200
          Rails.logger.warn "\e[31m[gemnasium] \e[1mGET /#{path}\e[0;31m responded with #{response.status}\e[0m"
          next
        end
        
        Array(JSON.load(response.body)).map { |alert| alert.merge(
          "project_id" => project["slug"],
          "project_slug" => project["name"]) }
      end.flatten.compact
    end
    
    def self.open
      all.select { |alert| alert["status"] != "closed" }
    end
    
  end
end
