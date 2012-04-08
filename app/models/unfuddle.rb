require 'net/https'

class Unfuddle
  
  def initialize(options={})
    options.reverse_merge!(Rails.application.config.unfuddle)
    @subdomain = options["subdomain"]
    @username = options["username"]
    @password = options["password"]
  end
  
  attr_reader :subdomain
  
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
  
end
