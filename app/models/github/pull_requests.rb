module Github
  class PullRequests
    include Enumerable
    
    def initialize(user)
      @user = user
      @results = nil
    end
    
    attr_reader :user
    
    def each(&block)
      to_h.each(&block)
    end
    
    def to_h
      fetch! if results.nil?
      results
    end
    
  private
    
    attr_reader :results, :token
    
    def fetch!
      ActiveRecord::Base.benchmark "\e[33mFetching pull requests \e[0m" do
        
        # !nb: this has no effect right now with pull requests
        # https://github.com/octokit/octokit.rb/pull/195#issuecomment-21811372
        # stack = Faraday::Builder.new do |builder|
        #   builder.response :logger if Rails.env.development?
        #   
        #   builder.use :http_cache, store: :memory_store
        #   builder.use Octokit::Response::RaiseError
        #   builder.adapter Faraday.default_adapter
        # end
        # Octokit.middleware = stack
        
        # c.f. http://developer.github.com/v3/repos/#list-organization-repositories
        repos = client.org_repos Houston::TMI::NAME_OF_GITHUB_ORGANIZATION
        
        queue = Queue.new
        repos.map do |repo|
          Thread.new do
            queue << {
              repo: repo,

              # c.f. http://developer.github.com/v3/pulls/#list-pull-requests
              pull_requests: client.pull_requests(repo.full_name)
            }
          end
        end.each(&:join)
        
        @results = map_results!(queue)
      end
    end
    
    def map_results!(queue)
      {}.tap do |results|
        until queue.empty?
          pair = queue.pop
          next if pair[:pull_requests].empty?
          results[pair[:repo]] = pair[:pull_requests]
        end
      end
    end
    
    def client
      @client ||= Octokit::Client.new(access_token: access_token)
    end
    
    def access_token
      raise Unauthorized unless token
      token.token
    end
    
    def token
      @token ||= user.consumer_tokens.first
    rescue RuntimeError
      raise unless $!.message =~ /refresh_token is not available/
      GithubToken.delete_all(user_id: user.id)
      nil
    end
    
  end
end
