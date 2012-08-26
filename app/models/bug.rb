class Bug
  
  def initialize(attributes={})
    @attributes = attributes
  end
  
  
  class << self
    
    def during(date_range)
      params = {start_date: date_range.begin, end_date: date_range.end}
      fetch_problems(params).map(&Bug.method(:from_problem))
    end
    
    def from_problem(problem)
      Bug.new(
        first_notice_at: problem[:first_notice_at],
        resolved: problem[:resolved],
        resolved_at: problem[:resolved_at],
        errbit_app_id: problem[:app_id]
      )
    end
    
    def fetch_problems(options={})
      protocol = Rails.application.config.errbit[:port] == 443 ? "https" : "http"
      root_url = "#{protocol}://#{Rails.application.config.errbit[:host]}"
      path = "#{root_url}/api/v1/problems.json"
      url = "#{path}?start_date=#{options[:start_date].strftime("%Y-%m-%d")}&end_date=#{options[:end_date].strftime("%Y-%m-%d")}&auth_token=#{Rails.application.config.errbit[:auth_token]}"
      response = Project.benchmark("[errbit] fetch \"#{url}\"") { Faraday.get(url) }
      problems = JSON.load(response.body)
      
      problems.map { |problem| problem["problem"].symbolize_keys }.reject { |problem| problem[:resolved] && problem[:resolved_at].nil? }
    end
    
  end
  
  
  
  def first_notice_at
    @attributes[:first_notice_at]
  end
  
  def resolved_at
    @attributes[:resolved_at]
  end
  
  def resolved?
    @attributes[:resolved]
  end
  
  def errbit_app_id
    @attributes[:errbit_app_id]
  end
  
  
end
