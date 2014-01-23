module Github
  class PullRequest
    
    def initialize(pull_request)
      @title = pull_request.title
      @number = pull_request.number
      @url = pull_request._links.html.href
      @user = pull_request.user
      @created_at = pull_request.created_at
    end
    
    attr_reader :title, :number, :url, :user, :created_at
    
    def gravatar_url(size: 64)
      "http://www.gravatar.com/avatar/#{user.gravatar_id}?r=g&d=identicon&s=#{size}"
    end
    
    def eligible?
      !back_burner?
    end
    
    def back_burner?
      title =~ /\((bb|wip)\)/
    end
    
  end
end
