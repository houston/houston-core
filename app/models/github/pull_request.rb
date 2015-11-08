module Github
  class PullRequest < ActiveRecord::Base
    self.table_name = "pull_requests"

    attr_readonly :project_id, :user_id, :repo, :number, :username, :base_ref, :base_sha, :url
    attr_accessor :actor

    belongs_to :project
    belongs_to :user
    has_and_belongs_to_many :commits

    before_validation :associate_project_with_self, if: :repo_changed?
    before_save :associate_user_with_self, if: :username_changed?
    after_commit :associate_commits_with_self, autosave: false

    after_destroy { Houston.observer.fire "github:pull:closed", self }
    after_create { Houston.observer.fire "github:pull:opened", self }
    after_update { Houston.observer.fire "github:pull:updated", self, changes }

    validates :project_id, :title, :number, :repo, :url, :base_ref, :base_sha, :head_ref, :head_sha, :username, presence: true
    validates :number, uniqueness: { scope: :project_id }

    class << self
      def fetch!
        Houston.benchmark "Fetching pull requests" do
          Houston.github.org_issues(Houston.config.github[:organization], filter: "all", state: "open")
            .select { |issue| !issue.pull_request.nil? }
            .map { |issue| Houston.github.pull_request(issue.repository.full_name, issue.number)
              .to_h
              .merge(labels: issue.labels.map(&:name))
              .with_indifferent_access }
        end
      end

      def sync!
        expected_pulls = fetch!
        expected_pulls.select! { |pr| pr["base"]["repo"]["name"] == pr["head"]["repo"]["name"] }
        # select only ones where head and base are the same repo
        Houston.benchmark "Syncing pull requests" do
          existing_pulls = all.to_a

          # Delete unexpected pulls
          existing_pulls.each do |existing_pr|
            unless expected_pulls.detect { |expected_pr|
              expected_pr["base"]["repo"]["name"] == existing_pr.repo &&
              expected_pr["number"] == existing_pr.number }
              existing_pr.destroy
            end
          end

          # Create or Update existing pulls
          expected_pulls.map do |expected_pr|
            existing_pr = existing_pulls.detect { |existing_pr|
              expected_pr["base"]["repo"]["name"] == existing_pr.repo &&
              expected_pr["number"] == existing_pr.number }

            existing_pr ||= Github::PullRequest.new
            existing_pr.merge_attributes(expected_pr)
            existing_pr.save if existing_pr.valid?
            existing_pr
          end
        end
      end

      def close!(github_pr, options={})
        pr = find_by(
          repo: github_pr["base"]["repo"]["name"],
          number: github_pr["number"])
        return unless pr

        pr.actor = options[:as]
        pr.destroy
      end

      def upsert!(github_pr, options={})
        retry_count ||= 0
        upsert(github_pr).tap do |pr|
          if pr.valid?
            pr.actor = options[:as]
            pr.save
          end
        end
      rescue ActiveRecord::RecordNotUnique
        retry unless (retry_count += 1) > 1
        raise
      end

      def upsert(github_pr)
        Github::PullRequest.find_or_initialize_by(
          repo: github_pr["base"]["repo"]["name"],
          number: github_pr["number"])
          .merge_attributes(github_pr)
      end
    end



    def labels
      super.split(/\n/)
    end

    def labels=(value)
      super Array(value).uniq.join("\n")
    end

    def add_label!(label, options={})
      transaction do
        pr = self.class.lock.find id
        pr.update_attributes! labels: pr.labels + [label], actor: options[:as]
      end
    end

    def remove_label!(label, options={})
      transaction do
        pr = self.class.lock.find id
        pr.update_attributes! labels: pr.labels - [label], actor: options[:as]
      end
    end



    def merge_attributes(pr)
      if new_record?
        self.repo = pr["base"]["repo"]["name"]
        self.number = pr["number"]
        self.username = pr["user"]["login"]
        self.url = pr["html_url"]
        self.base_sha = pr["base"]["sha"]
        self.base_ref = pr["base"]["ref"]
      end

      self.title = pr["title"]
      self.head_sha = pr["head"]["sha"]
      self.head_ref = pr["head"]["ref"]
      self.labels = pr["labels"] if pr.key?("labels")

      self
    end

  private

    def associate_project_with_self
      self.project = Project.find_by_slug(repo)
    end

    def associate_user_with_self
      self.user = User.find_by_nickname(username)
    end

    def associate_commits_with_self
      self.commits = project.commits.between(base_sha, head_sha)
    end

  end
end
