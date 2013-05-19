module Houston
  module Adapters
    module VersionControl
      class GitAdapter
        class GithubRepo < RemoteRepo
          
          
          def project_url
            location.to_s.gsub(/^git@(?:www\.)?github.com:/, "https://github.com/").gsub(/^git:/, "https:").gsub(/\.git$/, "")
          end

          def commit_url(sha)
            "#{project_url}/commit/#{sha}"
          end

          def commit_range_url(sha0, sha1)
            "#{project_url}/compare/#{sha0}...#{sha1}"
          end
          
          
        end
      end
    end
  end
end
