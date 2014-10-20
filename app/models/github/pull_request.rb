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
    
    def avatar_url(options={})
      url = user.avatar_url.dup
      url << "&s=#{options[:size]}" if options.key?(:size)
      url
    end
    
    def eligible?
      !back_burner?
    end
    
    def back_burner?
      title =~ /\((bb|wip)\)/
    end
    
  end
end
