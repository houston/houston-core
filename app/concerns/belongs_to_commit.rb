module BelongsToCommit
  extend ActiveSupport::Concern

  included do
    belongs_to :commit
    before_validation :identify_commit, on: :create
    validates :sha, presence: {message: "must refer to a commit"}
  end

  module ClassMethods
    def find_by_sha!(sha)
      find_by_sha(sha) || raise(ActiveRecord::RecordNotFound)
    end

    def find_by_sha(sha)
      with_sha_like(sha).first if sha
    end

    def with_sha_like(sha)
      where(["sha LIKE ?", "#{sha.strip}%"])
    end
  end

private

  def identify_commit
    return unless project && sha
    self.commit = project.find_commit_by_sha(sha)
    self.sha = commit.sha if commit
  rescue Houston::Adapters::VersionControl::InvalidShaError
    Rails.logger.warn "\e[31m[#{self.class.name.underscore}] Unable to identify commit\e[0m"
    Rails.logger.warn "#{$!.class}: #{$!.message}\n#{$!.backtrace.join("\n  ")}"
    nil
  end

end
