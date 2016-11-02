module Houston
  module Adapters
    module VersionControl
      class GitAdapter
        class GithubRepo < RemoteRepo


          def project_url
            location
              .gsub(/^git@(?:www\.)?github.com:/, "https://github.com/")
              .gsub(/^git:/, "https:")
              .gsub(/\.git$/, "")
          end

          def pulls_url
            "#{project_url}/pulls"
          end

          def commit_url(sha)
            "#{project_url}/commit/#{sha}"
          end

          def commit_range_url(sha0, sha1)
            "#{project_url}/compare/#{sha0}...#{sha1}"
          end

          def commit_status_url(sha)
            # GitHub requires the full 40-character sha
            sha = native_commit(sha).sha if sha.length < 40
            path = Addressable::URI.parse(project_url).path[1..-1]
            "https://api.github.com/repos/#{path}/statuses/#{sha}"
          end

          def repo_name
            Addressable::URI.parse(location).path[0...-4].gsub(/^\//, "")
          end

          def create_commit_status(sha, status={})
            status = OpenStruct.new(status) if status.is_a?(Hash)
            unless %w{pending success failure error}.member?(status.state)
              raise ArgumentError, ":state must be either 'pending', 'success', 'failure', or 'error'"
            end

            target_url = status.url if status.respond_to?(:url)
            target_url = status.target_url if status.respond_to?(:target_url)

            Houston.github.create_status(repo_name, sha, status.state, {
              context: status.context,
              target_url: target_url,
              description: status.description })
          end



          # GitHub API

          def pull_requests(options={})
            Houston.github.pull_requests(repo_name, options)
          end

          def create_pull_request(base: nil, head: nil, title: nil, body: nil, options: {})
            Houston.github.create_pull_request(repo_name, base, head, title, body, options)
          end

          def issues(options={})
            Houston.github.issues(repo_name, options)
          end

          def add_labels_to(labels, issue_number)
            issue_number = issue_number.number if issue_number.respond_to? :number
            Houston.github.add_labels_to_an_issue repo_name, issue_number, Array(labels)
          end
          alias :add_label_to :add_labels_to

          def remove_labels_from(labels, issue_number)
            issue_number = issue_number.number if issue_number.respond_to? :number
            Array(labels).each do |label|
              begin
                Houston.github.remove_label repo_name, issue_number, label
              rescue Octokit::NotFound
              end
            end
          end
          alias :remove_label_from :remove_labels_from

        end
      end
    end
  end
end
