require "test_helper"


class PullRequestTest < ActiveSupport::TestCase
  attr_reader :project, :pull_request


  context "Given GitHub API's description of a pull request" do
    setup do
      @project = Project.create!(
        name: "Test",
        slug: "test",
        version_control_name: "Git",
        extended_attributes: { "git_location" => Rails.root.join("test", "data", "bare_repo.git") })

      @pull_request_payload = {
        "number" => 1,
        "title" => "Divergent Branch",
        "html_url" => "https://github.com/houston",
        "user" => { "login" => "boblail" },
        "base" => {
          "repo" => { "name" => "test" },
          "sha" => "e0e4580f44317a084dd5142fef6b4144a4394819",
          "ref" => "master" }, # <-- I think this should be the full name
        "head" => {
          "sha" => "baa3ef218a40f23fe542f98d8b8e60a2e8e0bff0",
          "ref" => "divergent-branch" } }
    end

    context "When that pull request is created locally, it" do
      setup do
        @pull_request = Github::PullRequest.upsert(@pull_request_payload)
      end

      should "associate itself with all the commits" do
        pull_request.save!
        assert_equal %w{
          b3d156e4d4bb279e09cca0f31af8ea6e35d3df64
          baa3ef218a40f23fe542f98d8b8e60a2e8e0bff0},
          pull_request.commits.pluck(:sha)
      end
    end
  end


end
