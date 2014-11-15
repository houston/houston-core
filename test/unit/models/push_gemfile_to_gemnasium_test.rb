require "test_helper"

class PushGemfileToGemnasiumTest < ActiveSupport::TestCase
  attr_reader :project_path, :project
  
  
  setup do
    @project_path = Rails.root
    @project = Project.new(
      name: "Houston",
      gemnasium_slug: "SLUG",
      version_control_name: "Git",
      extended_attributes: {"git_location" => @project_path})
    PushGemfileToGemnasium.new(project).send :set_gemnasium_config!
  end
  
  
  context "#set_gemnasium_config!" do
    should "cause Gemnasium to be configured with the right site" do
      assert_equal "gemnasium.com", Gemnasium.config.site
    end
    
    should "cause Gemnasium to be configured with the right api_version" do
      assert_equal "v3", Gemnasium.config.api_version
    end
    
    should "cause Gemnasium to be configured with the right project slug" do
      assert_equal "SLUG", Gemnasium.config.project_slug
    end
    
    should "cause Gemnasium to be configured with the right project name" do
      assert_equal "Houston", Gemnasium.config.project_name
    end
    
    should "cause Gemnasium to be configured with the right project_slug" do
      assert_equal Houston.config.gemnasium[:api_key], Gemnasium.config.api_key
    end
  end
  
  
  context "#dependency_files_hashes" do
    should "return the same information as Gemnasium::DependencyFiles.get_sha1s_hash" do
      return skip "This test cannot be run when there are uncommitted changes to Gemfile.lock" if uncommitted_changes_to_gemfile?
      
      stub(Gemnasium.config).ignored_paths.returns [/lib\/freight_train/]
      hash_created_by_gemnasium = Gemnasium::DependencyFiles.get_sha1s_hash(project_path)
      hash_created_by_houston = PushGemfileToGemnasium.new(project).dependency_files_hashes
      assert_equal hash_created_by_gemnasium, hash_created_by_houston,
        "Houston calculated dependencies differently than Gemnasium.\n" <<
        "Note: this test may fail in error if you have uncomitted changes to your Gemfile."
    end
  end
  
  
  context "#content_to_upload" do
    should "return the same information as Gemnasium::DependencyFiles.get_content_to_upload" do
      return skip "This test cannot be run when there are uncommitted changes to Gemfile.lock" if uncommitted_changes_to_gemfile?
      
      files = %w{Gemfile Gemfile.lock}
      hash_created_by_gemnasium = Gemnasium::DependencyFiles.get_content_to_upload(project_path, files)
      hash_created_by_houston = PushGemfileToGemnasium.new(project).content_to_upload(files)
      assert_equal hash_created_by_gemnasium, hash_created_by_houston,
        "Houston generated dependencies differently than Gemnasium.\n" <<
        "Note: this test may fail in error if you have uncomitted changes to your Gemfile."
    end
  end
  
  
  context "Publishing Gemfiles to Gemnasium" do
    setup do
      modified_files = %w{Gemfile.lock}
      stub(Gemnasium.config).ignored_paths.returns [/lib\/freight_train/]
      
      # How Gemnasium works:
      
      expected_url = "https://X:#{Gemnasium.config.api_key}@gemnasium.com/api/v3" <<
                     "/projects/#{Gemnasium.config.project_slug}/dependency_files/compare"
      expected_body = MultiJson.dump(Hash[Gemnasium::DependencyFiles.get_sha1s_hash(project_path).sort])
      
      expected_headers = {
        "Accept" => "application/json",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "Content-Type" => "application/json",
        "User-Agent" => "Ruby" }
      response = MultiJson.dump({
        "to_upload" => modified_files,
        "deleted" => []})
      stub_request(:post, expected_url) \
        .with(body: expected_body, headers: expected_headers) \
        .to_return(status: 200, body: response, headers: {})
      
      expected_url = "https://X:#{Gemnasium.config.api_key}@gemnasium.com/api/v3" <<
                     "/projects/#{Gemnasium.config.project_slug}/dependency_files/upload"
      expected_body = MultiJson.dump(Gemnasium::DependencyFiles.get_content_to_upload(project_path, modified_files))
      response = MultiJson.dump({
        "added" => modified_files,
        "updated" => [],
        "unchanged" => [],
        "unsupported" => []})
      stub_request(:post, expected_url) \
        .with(body: expected_body, headers: expected_headers) \
        .to_return(status: 200, body: response, headers: {})
    end
    
    should "be stubbed according to Gemnasium's behavior" do
      return skip "This test cannot be run unless Houston is on master, but HEAD is #{head}" if not_on_master?
      
      stub(Gemnasium).load_config(project_path).returns(Gemnasium.config) # do nothing
      Gemnasium.push(project_path: project_path)
    end
    
    should "work the way Gemnasium does" do
      return skip "This test cannot be run when there are uncommitted changes to Gemfile.lock" if uncommitted_changes_to_gemfile?
      
      PushGemfileToGemnasium.new(project).perform
    end
  end
  
  
  
private
  
  def head
    @head ||= (repo.head.name == "HEAD" ? "(unknown)" : repo.head.name)
  end
  
  def not_on_master?
    head != "refs/heads/master"
  end
  
  def uncommitted_changes_to_gemfile?
    !repo.status("Gemfile.lock").empty?
  end
  
  def repo
    @repo ||= Rugged::Repository.new(Rails.root.to_s)
  end
  
end
