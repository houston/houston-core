module Github
  class PullRequest
    
    def initialize(pull_request)
      @raw_pull_request = pull_request
      @title = pull_request.title
      @number = pull_request.number
      @user = pull_request.user
      @created_at = pull_request.created_at
      @repo = pull_request.repository.name
      @url = "https://github.com/#{pull_request.repository.full_name}/pull/#{number}"
    end
    
    attr_reader :raw_pull_request, :title, :number, :url, :user, :created_at, :repo
    
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
