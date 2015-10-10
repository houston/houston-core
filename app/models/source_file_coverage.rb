class SourceFileCoverage < SimpleCov::SourceFile

  def initialize(project, commit, filename, coverage)
    @project, @filename, @coverage = project, filename, coverage
    @src = @project.read_file(filename, commit: commit).to_s.lines
  rescue Houston::Adapters::VersionControl::FileNotFound
    @src = []
  end

end
