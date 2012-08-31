class CommitPresenter
  
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
    { id: commit.id,
      
      # NB: we want to sort these with TesterNotes
      #     by the field 'createdAt', so while this
      #     _actually_ represents 'releasedAt', we'll
      #     call it 'createdAt' for now.
      createdAt: commit.release.created_at, 
      message: commit.message,
      committer: {
        name: commit.committer,
        email: commit.committer_email } }
  end
  
end
