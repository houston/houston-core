module Houston
  module Adapters
    module TicketTracker
      class GithubAdapter
        class Connection
          
          def initialize(repo_path)
            @repo_path = repo_path
            @config = Houston.config.ticket_tracker_configuration(:github)
          end
          
          
          
          # Required API
          
          def build_ticket(attributes)
            attributes["user"] = {} unless attributes["user"]
            attributes["user"]["email"] = find_user_email(attributes["user"]["login"])
            Houston::Adapters::TicketTracker::GithubAdapter::Issue.new(self, attributes)
          end
          
          def create_ticket!(houston_ticket)
            as_user(houston_ticket.reporter) do
              attrs = get_attributes_from_type(houston_ticket.type)
              options = {}
              options[:labels] = attrs[:labels].join(",") if attrs[:labels]
              
              native_ticket = client.create_issue(
                repo_path,
                houston_ticket.summary,
                houston_ticket.description,
                options )
              
              build_ticket(native_ticket)
            end
          end
          
          def find_ticket_by_number(number)
            attributes = client.issue(repo_path, number) unless number.blank?
            build_ticket(attributes) if attributes
          end
          
          def find_tickets_numbered(*numbers)
            numbers = numbers.flatten
            return [] if numbers.empty?
            return numbers.map(&method(:find_ticket_by_number)) if numbers.length < 5
            open_tickets.select { |ticket| numbers.member?(ticket.number) }
          end
          
          def all_tickets
            open_tickets + closed_tickets
          end
          
          def open_tickets
            remote_issues = client.list_issues(repo_path, state: "open")
            remote_issues.map { |attributes | build_ticket(attributes) }
          end
          
          def project_url
            "https://github.com/#{repo_path}/issues"
          end
          
          def ticket_url(ticket_number)
            "#{project_url}/#{ticket_number}"
          end
          
          
          
          def all_milestones
            []
          end
          
          def open_milestones
            []
          end
          
          
          
          # Idiomatic API
          
          attr_reader :repo_path, :config
          
          def client
            @client ||= Octokit::Client.new(Houston.config.github.pick(:access_token).merge(auto_paginate: true))
          end
          
          
          
          def as_user(user, &block)
            current_client = @client
            begin
              token = user.consumer_tokens.first
              # !todo: use a more generic exception?
              raise Github::Unauthorized unless token
              @client = Octokit::Client.new(access_token: token.token)
              yield
            ensure
              @client = current_client
            end
          end
          
          
          
        private
          
          def find_user_email(user_login)
            return nil if user_login.nil?
            find_in_cache_or_execute(user_key(user_login)) do
              user = client.user user_login
              user.email if user
            end
          end
          
          def user_key(user_login)
            "github/users/#{user_login}"
          end
          
          def find_in_cache_or_execute(key, &block)
            Rails.cache.fetch(key, &block)
          end
          
          def invalidate_cache!(*keys)
            keys.each do |key|
              Rails.cache.delete key
            end
          end
          
          def get_attributes_from_type(type)
            attributes_from_type_proc = config[:attributes_from_type]
            return {} unless attributes_from_type_proc
            attributes_from_type_proc.call(type)
          end
          
          def closed_tickets
            remote_issues = client.list_issues(repo_path, state: "closed")
            remote_issues.map { |attributes | build_ticket(attributes) }
          end
          
        end
      end
    end
  end
end
