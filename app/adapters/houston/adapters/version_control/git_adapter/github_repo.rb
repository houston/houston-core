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
            path = Addressable::URI.parse(location).path[0...-4]
            "https://api.github.com/repos/#{path}/statuses/#{full_sha}"
          end
          
          
        end
      end
    end
  end
end
