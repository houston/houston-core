class PushGemfileToGemnasium
  attr_reader :project
  
  def initialize(project)
    @project = project
  end
  
  def perform
    set_gemnasium_config!
    upload_files! unless files_to_upload.empty?
  end
  
  def upload_files!
    request "#{connection.api_path_for("dependency_files")}/upload", content_to_upload(files_to_upload)
  end
  
  def files_to_upload
    @files_to_upload ||= begin
      comparison_results = request("#{connection.api_path_for("dependency_files")}/compare", dependency_files_hashes)
      comparison_results["to_upload"]
    end
  end
  
  # !todo: actually scan for files rather than _knowing_ where to find them
  def dependency_files_hashes
    @dependency_files_hashes ||= begin
      { "Gemfile" =>      project.repo.find_file("Gemfile").oid,
        "Gemfile.lock" => project.repo.find_file("Gemfile.lock").oid }
    end
  end
  
  def content_to_upload(files_path)
    files_path.map do |file|
      blob = project.repo.find_file(file)
      { filename: file, sha: blob.oid, content: blob.content }
    end
  end
  
private
  
  def set_gemnasium_config!
    Gemnasium.instance_variable_set :@config, Config.new(project)
  end
  
  def request(*args)
    Gemnasium.send :request, *args
  end
  
  def connection
    Gemnasium.send :connection
  end
  
  class Config
    attr_reader :project_name, :project_slug, :project_branch, :api_key
    
    def initialize(project)
      @project_name = project.name
      @project_slug = project.gemnasium_slug
      @project_branch = project.gemnasium_branch
      @api_key = Houston.config.gemnasium[:api_key]
    end
    
    def site
      "gemnasium.com"
    end
    
    def use_ssl
      true
    end
    
    def api_version
      "v3"
    end
    
    def ignored_paths
      []
    end
    
    def needs_to_migrate?
      false
    end
    
    def is_valid?
      true
    end
    
  end
end
