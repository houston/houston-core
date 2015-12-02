class ProjectDependencies < SimpleDelegator

  def model
    __getobj__
  end

  def platform
    @platform ||= begin
      if dependency_version("rails") then "rails"
      else ""
      end
    end
  end

  def database
    @database = guess_database unless defined?(@database)
    @database
  end

  def guess_database
    return nil unless can_determine_dependencies?
    return "Postgres" if dependency_version("pg")
    return "MySQL" if dependency_version("mysql") || dependency_version("mysql2")
    return "SQLite" if dependency_version("sqlite3")
    return "MongoDB" if dependency_version("mongoid")
    "None"
  end

  def dependency_version(dependency)
    spec = locked_gems.specs.find { |spec| spec.name == dependency } if locked_gems
    spec.version if spec
  end

  def can_determine_dependencies?
    !!locked_gems
  end

  def locked_gems
    @locked_gems = lockfile && Bundler::LockfileParser.new(lockfile) unless defined?(@locked_gems)
    @locked_gems
  end

  def lockfile
    return @lockfile if defined?(@lockfile)
    return "" unless repo.exists?

    Houston.benchmark "[project_dependencies.lockfile] #{slug}" do
      @lockfile = read_file("Gemfile.lock", commit: head_sha)
    end
  rescue Houston::Adapters::VersionControl::FileNotFound
    @lockfile = ""
  end

end
