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
