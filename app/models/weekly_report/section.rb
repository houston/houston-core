class WeeklyReport
  class Section
    
    def initialize(title: nil, template: title.downcase, icon_url: nil, context: nil)
      @title = title
      @template = template
      @icon_url = icon_url
      @context = context
    end
    
    attr_reader :title, :template, :icon_url, :context
    
  end
end
