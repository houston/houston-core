module Github
  class PullRequest < ActiveRecord::Base
    include Houston::Props

    self.table_name = "pull_requests"

    attr_readonly :project_id, :user_id, :repo, :number, :username, :base_ref, :url
    attr_accessor :actor

    belongs_to :project
    belongs_to :user
    has_and_belongs_to_many :commits
    belongs_to :base, class_name: "Commit", foreign_key: "base_sha", primary_key: "sha"
    belongs_to :head, class_name: "Commit", foreign_key: "head_sha", primary_key: "sha"

    before_validation :associate_project_with_self, if: :repo_changed?
    before_save :associate_user_with_self, if: :username_changed?
    after_commit :associate_commits_with_self

    after_create do
      Houston.observer.fire "github:pull:opened", pull_request: self
      true
    end

    after_update do
      Houston.observer.fire "github:pull:updated", pull_request: self, changes: changes
      Houston.observer.fire "github:pull:closed", pull_request: self if closed_at_changed? && closed_at
      Houston.observer.fire "github:pull:reopened", pull_request: self if closed_at_changed? && !closed_at
      true
    end

    validates :project_id, :title, :number, :repo, :url, :base_ref, :base_sha, :head_ref, :head_sha, :username, presence: true
    validates :number, uniqueness: { scope: :project_id }

    class << self
      # Makes X + Y requests to GitHub
      # where X is the number of projects in Houston on GitHub
      # and Y is the number of pull requests for those projects
      #
      # We _could_ group repos by their owner and fetch `org_issues`
      # but that will only work for organizations, not personal
      # accounts.
      #
      # This method can chomp through your rate limit rather quickly.
      # Also, on my computer it took 19 seconds to fetch 39 pull
      # requests from 52 repos.
      def fetch!(projects = Project.unretired)
        repos = projects
          .where("props->>'git.location' LIKE '%github.com%'")
          .pluck("props->>'git.location'")
          .map { |url| _repo_name_from_url(url) }
          .compact

        Houston.benchmark "Fetching pull requests" do
          requests = 0
          issues = repos.flat_map do |repo|
            _fetch_issues_for!(repo).tap do |results|
              requests += 1 + (results.length / 30)
            end
          end

          pulls = issues
            .select { |issue| !issue.pull_request.nil? }
            .map { |issue|
              requests += 1
              repo = issue.pull_request.url[/https:\/\/api.github.com\/repos\/(.*)\/pulls\/\d+/, 1]
              Houston.github.pull_request(repo, issue.number)
                .to_h
                .merge(labels: issue.labels)
                .with_indifferent_access }

          Rails.logger.info "[pulls] #{requests} requests; #{Houston.github.last_response.headers["x-ratelimit-remaining"]} remaining"
          pulls
        end
      end

      def _repo_name_from_url(url)
        url[/\Agit@github\.com:(.*)\.git\Z/, 1] || url[/\Agit:\/\/github.com\/(.*)\.git\Z/, 1]
      end

      def _fetch_issues_for!(repo)
        if repo.end_with? "/*"
          Houston.github.org_issues(repo[0...-2], filter: "all", state: "open")
        else
          Houston.github.issues(repo, filter: "all", state: "open")
        end
      rescue Octokit::NotFound
        []
      end

      def sync!(projects = Project.unretired)
        expected_pulls = fetch!(projects)
        existing_pulls = Houston.benchmark "Loading pull requests" do
          open.where(project_id: projects.ids).to_a
        end
        Houston.benchmark "Syncing pull requests" do

          # Fetch unexpected pulls so that we know
          # when they were closed and whether they
          # were merged.
          existing_pulls.each do |existing_pr|
            unless expected_pulls.detect { |expected_pr|
              expected_pr["base"]["repo"]["name"] == existing_pr.repo &&
              expected_pr["number"] == existing_pr.number }
              expected_pulls << existing_pr.fetch!
            end
          end

          # Create or Update existing pulls
          expected_pulls.map do |expected_pr|
            existing_pr = existing_pulls.detect { |existing_pr|
              expected_pr["base"]["repo"]["name"] == existing_pr.repo &&
              expected_pr["number"] == existing_pr.number }

            # Maybe the pull request was closed?
            existing_pr ||= where(repo: expected_pr["base"]["repo"]["name"], number: expected_pr["number"]).first

            existing_pr ||= Github::PullRequest.new
            existing_pr.merge_attributes(expected_pr)
            if existing_pr.changes.any?
              unless existing_pr.save
                Rails.logger.warn "\e[31m[pulls] Invalid PR: #{existing_pr.errors.full_messages.join("; ")}\e[0m"
              end
            end
            existing_pr
          end
        end
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

      def open
        where(closed_at: nil)
      end

      def closed
        where.not(closed_at: nil)
      end

      def merged
        where.not(merged_at: nil)
      end

      def labeled(*labels)
        where(["exists (select 1 from jsonb_array_elements(pull_requests.json_labels) as \"label\" where \"label\"->>'name' IN (?))", labels])
      end
      alias :with_labels :labeled

      def without_labels(*labels)
        where(["not exists (select 1 from jsonb_array_elements(pull_requests.json_labels) as \"label\" where \"label\"->>'name' IN (?))", labels])
      end
    end



    def labels=(value)
      self.json_labels = value.map { |label| label.to_h.stringify_keys.pick("name", "color") }
    end

    def labeled?(*values)
      values.all? { |value| labels.any? { |label| label["name"] == value } }
    end

    def labeled_any?(*values)
      values.any? { |value| labels.any? { |label| label["name"] == value } }
    end

    def labels
      json_labels
    end

    def add_labels!(*labels)
      Houston.github.add_labels_to_an_issue full_repo, number, Array(labels)
    end
    alias :add_label! :add_labels!

    def remove_labels!(*labels)
      Array(labels).each do |label|
        begin
          Houston.github.remove_label full_repo, number, label
        rescue Octokit::NotFound
        end
      end
    end
    alias :remove_label! :remove_labels!



    def to_s
      "#{repo}##{number}"
    end



    def publish_commit_status!(status={})
      project.repo.create_commit_status(head_sha, status)
    end

    def full_repo
      url[/https:\/\/github.com\/(.*)\/pull\/\d+/, 1]
    end

    def fetch!
      Houston.github.pull_request(full_repo, number).to_h.with_indifferent_access
    end



    def merge_attributes(pr)
      self.repo = pr["base"]["repo"]["name"] unless repo
      self.number = pr["number"] unless number
      self.username = pr["user"]["login"] unless username
      self.avatar_url = pr["user"]["avatar_url"] unless avatar_url
      self.url = pr["html_url"] unless url
      self.base_ref = pr["base"]["ref"] unless base_ref
      self.head_ref = pr["head"]["ref"] unless head_ref
      self.created_at = pr["created_at"] unless created_at

      self.title = pr["title"]
      self.body = pr["body"]
      self.base_sha = pr["base"]["sha"]
      self.head_sha = pr["head"]["sha"]
      self.closed_at = pr["closed_at"]
      self.merged_at = pr["merged_at"]
      self.labels = pr["labels"] if pr.key?("labels")

      self
    end

  private

    def associate_project_with_self
      self.project = Project.find_by_slug(repo)
    end

    def associate_user_with_self
      self.user = User.find_by_github_username(username)
    end

    def associate_commits_with_self
      return unless commits_changes_before_commit?

      Houston.try({max_tries: 2, base: 0},
          exceptions_wrapping(PG::LockNotAvailable),
          ActiveRecord::RecordNotUnique) do
        self.commits = project.commits.between(base_sha, head_sha)
      end

      Houston.observer.fire "github:pull:synchronize", pull_request: self
    end

    def commits_changes_before_commit?
      previous_changes.key?(:base_sha) || previous_changes.key?(:head_sha)
    end

  end
end
