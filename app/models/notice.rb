class Notice
  
  def initialize(attributes={})
    @attributes = attributes
  end
  
  
  class << self
    
    def during(date_range)
      params = {start_date: date_range.begin, end_date: date_range.end}
      fetch_notices(params).map(&Notice.method(:from_notice))
    end
    
    def from_notice(notice)
      Notice.new(
        created_at: notice[:created_at].try(:to_time)
      )
    end
    
    def fetch_notices(options={})
      protocol = Rails.application.config.errbit[:port] == 443 ? "https" : "http"
      root_url = "#{protocol}://#{Rails.application.config.errbit[:host]}"
      path = "#{root_url}/api/v1/notices.json"
      url = "#{path}?start_date=#{options[:start_date].strftime("%Y-%m-%d")}&end_date=#{options[:end_date].strftime("%Y-%m-%d")}&auth_token=#{Rails.application.config.errbit[:auth_token]}"
      response = Project.benchmark("[errbit] fetch \"#{url}\"") { Faraday.get(url) }
      notices = Yajl.load(response.body)
      
      notices.map { |notice| notice.symbolize_keys }
    end
    
  end
  
  
  
  def created_at
    @attributes[:created_at]
  end
  
  
end
