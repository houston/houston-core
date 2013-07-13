class CommitPresenter
  include UrlHelper
  
  def initialize(commits)
    @commits = commits
  end
  
  def as_json(*args)
    if @commits.is_a?(Commit)
      to_hash @commits
    else
      @commits.map(&method(:to_hash))
    end
  end
  
  def to_hash(commit)
    hash = { id: commit.id,
      message: commit.message,
      sha: commit.sha,
      linkTo: github_commit_url(commit.project, commit.sha), # <-- !todo: more abstract
      committer: {
        name: commit.committer,
        email: commit.committer_email } }
    if commit.release
      # NB: we want to sort these with TesterNotes
      #     by the field 'createdAt', so while this
      #     _actually_ represents 'releasedAt', we'll
      #     call it 'createdAt' for now.
      hash[:createdAt] = commit.release.created_at
      hash[:environment] = commit.release.environment_name
    end
    hash
  end
  
end
