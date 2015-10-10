class Environment

  def initialize(project, environment_name)
    @project = project
    @environment_name = environment_name
  end

  attr_reader :project, :environment_name

  def last_deploy
    @last_deploy ||= project.deploys.completed.to(environment_name).first
  end

  def head
    return (environment_name == "Production" ? "c7c7380" : "98318a3") if Rails.env.development?
    @head ||= last_deploy.try(:commit)
  end

  def read_file(path)
    project.read_file(path, commit: head) if head
  rescue Houston::Adapters::VersionControl::CommitNotFound
    nil
  end



  def dependency_version(dependency)
    lockfile = read_file("Gemfile.lock")
    return nil unless lockfile

    dependency = dependency.to_s
    locked_gems = Bundler::LockfileParser.new(lockfile)
    spec = locked_gems.specs.find { |spec| spec.name == dependency }
    spec.version if spec
  end



end
