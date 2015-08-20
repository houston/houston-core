module Github
  class PullRequest < ActiveRecord::Base
    self.table_name = "pull_requests"

    belongs_to :project
    belongs_to :user
    has_and_belongs_to_many :commits

    before_validation :associate_project_with_self, if: :repo_changed?
    before_save :associate_user_with_self, if: :username_changed?
    before_save :associate_commits_with_self, if: :head_sha_changed?

    validates :project_id, :title, :number, :repo, :url, :base_ref, :base_sha, :head_ref, :head_sha,
      presence: true

    class << self
      def fetch!
        Houston.benchmark "Fetching pull requests" do
          Houston.github.org_issues(Houston.config.github[:organization], filter: "all", state: "open")
            .select { |issue| !issue.pull_request.nil? }
            .map { |issue| Houston.github.pull_request(issue.repository.full_name, issue.number) }
        end
      end

      def sync!
        expected_pulls = fetch!
        expected_pulls.select! { |pr| pr.base.repo.name == pr.head.repo.name }
        # select only ones where head and base are the same repo
        Houston.benchmark "Syncing pull requests" do
          existing_pulls = all.to_a

          # Delete unexpected pulls
          existing_pulls.each do |existing_pr|
            unless expected_pulls.detect { |expected_pr|
              expected_pr.base.repo.name == existing_pr.repo &&
              expected_pr.number == existing_pr.number }
              existing_pr.destroy
            end
          end

          # Create or Update existing pulls
          expected_pulls.map do |expected_pr|
            existing_pr = existing_pulls.detect { |existing_pr| 
              expected_pr.base.repo.name == existing_pr.repo &&
              expected_pr.number == existing_pr.number }

            existing_pr ||= Github::PullRequest.new
            existing_pr.merge_attributes(expected_pr)
            existing_pr.save
            existing_pr
          end
        end
      end

      def close!(github_pr)
        pr = find_by(
          repo: github_pr["base"]["repo"]["name"],
          number: github_pr["number"])
        pr.destroy if pr
      end

      def upsert!(github_pr)
        Github::PullRequest.find_or_initialize_by(
          repo: github_pr["base"]["repo"]["name"],
          number: github_pr["number"])
          .merge_attributes(github_pr)
          .tap(&:save!)
      end
    end



    def merge_attributes(pr)
      self.title = pr["title"]
      self.number = pr["number"]
      self.repo = pr["base"]["repo"]["name"],
      self.username = pr["user"]["login"]
      self.url = pr["html_url"]
      self.base_sha = pr["base"]["sha"]
      self.base_ref = pr["base"]["ref"]
      self.head_sha = pr["head"]["sha"]
      self.head_ref = pr["head"]["ref"]
    end

  private

    def associate_project_with_self
      self.project = Project.find_by_slug(repo)
    end

    def associate_user_with_self
      self.user = User.find_by_nickname(username)
    end

    def associate_commits_with_self
      self.commits = project.commits.between(base_sha, head_sha) if project
    end

  end
end
