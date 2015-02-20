module Houston
  module Adapters
    module VersionControl
      class GitAdapter
        class GithubRepo < RemoteRepo
          
          
          def project_url
            location.to_s
              .gsub(/^git@(?:www\.)?github.com:/, "https://github.com/")
              .gsub(/^git:/, "https:")
              .gsub(/\.git$/, "")
          end
          
          def commit_url(sha)
            "#{project_url}/commit/#{sha}"
          end
          
          def commit_range_url(sha0, sha1)
            "#{project_url}/compare/#{sha0}...#{sha1}"
          end
          
          def commit_status_url(sha)
            full_sha = native_commit(sha).sha # GitHub requires the full 40-character sha
            path = Addressable::URI.parse(project_url).path[1..-1]
            "https://api.github.com/repos/#{path}/statuses/#{full_sha}"
          end
          
          def repo_name
            location.path[0...-4]
          end
          
          
          
          # GitHub API
          
          def pull_requests(options={})
            Houston.github.pull_requests(repo_name, options)
          end
          
          def issues(options={})
            Houston.github.issues(repo_name, options)
          end
          
          def add_label_to(label, issue_number)
            issue_number = issue_number.number if issue_number.respond_to? :number
            Houston.github.add_labels_to_an_issue repo_name, issue_number, [label]
          end
          
          def remove_label_from(label, issue_number)
            issue_number = issue_number.number if issue_number.respond_to? :number
            Houston.github.remove_label repo_name, issue_number, label
          end
          
        end
      end
    end
  end
end
