module Gemnasium
  class Alert

    def self.all
      connection = Faraday.new(url: "https://api.gemnasium.com/v1/")
      connection.basic_auth "X", $GEMNASIUM_API_KEY
      connection.use Faraday::RaiseErrors

      response = connection.get "projects"
      projects = MultiJson.load(response.body).values.flatten

      projects.parallel.map do |project|
        response = connection.get "projects/#{project["slug"]}/alerts"
        Array(MultiJson.load(response.body)).map { |alert| alert.merge(
          "project_id" => project["slug"],
          "project_slug" => project["name"]) }
      end.flatten.compact
    end

    def self.open
      all.select { |alert| alert["status"] != "closed" }
    end

  end
end
