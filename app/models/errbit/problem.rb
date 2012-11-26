module Errbit
  class Problem
    
    def initialize(attributes={})
      @attributes = attributes
    end
    
    
    class << self
      
      def during(date_range)
        params = {start_date: date_range.begin, end_date: date_range.end}
        fetch_problems(params).map(&self.method(:from_problem))
      end
      
      def from_problem(problem)
        self.new(
          first_notice_at: problem[:first_notice_at].try(:to_time),
          resolved: problem[:resolved],
          resolved_at: problem[:resolved_at].try(:to_time),
          errbit_app_id: problem[:app_id]
        )
      end
      
      def fetch_problems(options={})
        return fake_fetch_problems(options) if Rails.env.development?
        
        protocol = Houston.config.errbit[:port] == 443 ? "https" : "http"
        root_url = "#{protocol}://#{Houston.config.errbit[:host]}"
        path = "#{root_url}/api/v1/problems.json"
        url = "#{path}?start_date=#{options[:start_date].strftime("%Y-%m-%d")}&end_date=#{options[:end_date].strftime("%Y-%m-%d")}&auth_token=#{Houston.config.errbit[:auth_token]}"
        response = Project.benchmark("[errbit] fetch \"#{url}\"") { Faraday.get(url) }
        problems = Yajl.load(response.body)
        
        problems.map { |problem| problem.symbolize_keys }.reject { |problem| problem[:resolved] && problem[:resolved_at].nil? }
      end
      
      def fake_fetch_problems(options={})
        project_ids = Project.pluck(:errbit_app_id).select { |id| !id.blank? } + [-56, -1231]
        
        before_week = 5.days.until(options[:start_date].to_time).to_s
        during_week = 3.days.until(options[:end_date].to_time).to_s
        after_week = 1.day.since(options[:end_date].to_time).to_s
        
        problems = []
        project_ids.each do |project_id|
          rand(5).times { problems << {first_notice_at: before_week, resolved: true, resolved_at: during_week, app_id: project_id} }  # Resolved
          rand(25).times { problems << {first_notice_at: before_week, resolved: false, resolved_at: nil, app_id: project_id} }          # Open
          rand(5).times { problems << {first_notice_at: during_week, resolved: false, resolved_at: nil, app_id: project_id} }            # New
        end
        
        problems
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
end
