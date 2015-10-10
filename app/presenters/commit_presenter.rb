class CommitPresenter
  include UrlHelper

  def initialize(commits)
    @commits = OneOrMany.new(commits)
  end

  def as_json(*args)
    @commits.map(&method(:commit_to_json))
  end

  def commit_to_json(commit)
    hash = {
      id: commit.id,
      sha: commit.sha,
      message: commit.summary,
      project: commit.project.slug,
      linkTo: github_commit_url(commit.project, commit.sha), # <-- !todo: more abstract
      committer: {
        name: commit.committer,
        email: commit.committer_email } }

    release = commit.releases.earliest
    if release
      # NB: we want to sort these with TesterNotes
      #     by the field 'createdAt', so while this
      #     _actually_ represents 'releasedAt', we'll
      #     call it 'createdAt' for now.
      hash[:createdAt] = release.created_at
      hash[:environment] = release.environment_name
    end
    hash
  end

  def verbose
    @commits.map do |commit|
      commit_to_json(commit).merge({
        tag: commit.tags.first,
        hours: commit.hours_worked,
        tickets: commit.ticket_numbers,
        unreachable: commit.unreachable,
        releases: commit.releases.map { |release| {
          environment: release.environment_name,
          createdAt: release.created_at } },
        committers: commit.committers.map { |committer| {
          id: committer.id,
          email: committer.email,
          name: committer.name } } })
    end
  end

end
