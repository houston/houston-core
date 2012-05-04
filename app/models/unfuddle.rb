require 'net/https'
require 'unfuddle/project'

class Unfuddle
  
  def self.instance
    @unfuddle ||= self.new
  end
  
  attr_reader :subdomain,
              :username,
              :password
  
  def http
    @http ||= Net::HTTP.new("#{@subdomain}.unfuddle.com", 443).tap do |http|
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
  end
  
  def get(path)
    path = "/api/v1#{path}"
    request = Net::HTTP::Get.new(path)
    request.basic_auth @username, @password
    http.request(request)
  end
  
  def post(path, params)
    path = "/api/v1#{path}"
    request = Net::HTTP::Post.new(path, {"Content-type" => "application/json"})
    request.basic_auth @username, @password
    Rails.logger.info "[unfuddle:post]\n  #{path}\n  #{JSON.dump(params)}"
    http.request(request, JSON.dump(params))
  end
  
  def put(path, xml)
    path = "/api/v1#{path}"
    request = Net::HTTP::Put.new(path, {"Content-type" => "application/xml"})
    request.basic_auth @username, @password
    Rails.logger.info "[unfuddle:put]\n  #{path}\n  #{xml}"
    http.request(request, xml)
  end
  
  def project(project_id)
    ::Unfuddle::Project.new(self, project_id)
  end
  
protected
  
  def initialize(options={})
    options.reverse_merge!(Rails.application.config.unfuddle)
    @subdomain = options["subdomain"]
    @username = options["username"]
    @password = options["password"]
  end
  
end
