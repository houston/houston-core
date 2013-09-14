class SourceFileCoverage < SimpleCov::SourceFile
  
  def initialize(project, commit, filename, coverage)
    @project, @filename, @coverage = project, filename, coverage
    @src = @project.read_file(filename, commit: commit).lines
  end
  
end
