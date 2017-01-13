class CommitPresenter
  include UrlHelper

  def initialize(commits)
    @commits = OneOrMany.new(commits)
  end

  def as_json(*args)
    @commits.map(&method(:commit_to_json))
  end

  def commit_to_json(commit)
    { id: commit.id,
      sha: commit.sha,
      message: commit.summary,
      project: commit.project.slug,
      linkTo: github_commit_url(commit.project, commit.sha), # <-- !todo: more abstract
      committer: {
        name: commit.committer,
        email: commit.committer_email } }
  end

  def verbose
    @commits.map do |commit|
      commit_to_json(commit).merge({
        tag: commit.tags.first,
        hours: commit.hours_worked,
        tickets: commit.ticket_numbers,
        unreachable: commit.unreachable,
        committers: commit.committers.map { |committer| {
          id: committer.id,
          email: committer.email,
          name: committer.name } } })
    end
  end

end
