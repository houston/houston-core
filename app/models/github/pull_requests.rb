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
    
    def to_a
      fetch! if results.nil?
      results
    end
    
    def to_h
      fetch! if results.nil?
      results.group_by(&:repo)
    end
    
  private
    
    attr_reader :results, :token
    
    def fetch!
      ActiveRecord::Base.benchmark "\e[33mFetching pull requests \e[0m" do
        @results = client.org_issues(Houston.config.github[:organization], filter: "all", state: "open")
          .select(&method(:pull_request?))
          .map(&::Github::PullRequest.method(:new))
          .sort_by { |pull| [pull.repo, -pull.number] }
      end
    end
    
    def client
      @client ||= Octokit::Client.new(access_token: access_token, auto_paginate: true)
    end
    
    def access_token
      raise Unauthorized unless token
      token.token
    end
    
    def token
      @token ||= user.consumer_tokens.first
    end
    
    def pull_request?(issue)
      issue.pull_request._rels.size > 0
    end
    
  end
end
