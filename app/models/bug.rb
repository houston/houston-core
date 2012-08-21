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
        resolved_at: problem[:resolved_at],
        project_id: problem[:app_id]
      )
    end
    
    def fetch_problems(options={})
      # Errbit Problems where first_notice_at <= range.end and resolved_at >= range.begin
      
      project_ids = Project.pluck(:id)
      
      before_week = 5.days.until(options[:start_date])
      during_week = 1.day.since(options[:start_date])
      after_week = 1.day.since(options[:end_date])
      
      problems = []
      project_ids.each do |project_id|
        rand(14).times { problems << {first_notice_at: before_week, resolved_at: during_week, app_id: project_id} } +  # Resolved
        rand(50).times { problems << {first_notice_at: before_week, resolved_at: nil, app_id: project_id} } +          # Open
        rand( 8).times { problems << {first_notice_at: during_week, resolved_at: nil, app_id: project_id} }            # New
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
    !resolved_at.nil?
  end
  
  def project_id
    @attributes[:project_id]
  end
  
  
end
