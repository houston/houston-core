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
        "body" => "This is the description of the pull request",
        "base" => {
          "repo" => { "name" => "test" },
          "sha" => "e0e4580f44317a084dd5142fef6b4144a4394819",
          "ref" => "master" },
        "head" => {
          "sha" => "baa3ef218a40f23fe542f98d8b8e60a2e8e0bff0",
          "ref" => "divergent-branch" } }
    end

    context "When that pull request is created locally, it" do
      setup do
        @pull_request = Github::PullRequest.upsert(@pull_request_payload)
      end

      should "have 'title'" do
        assert_equal @pull_request_payload["title"], @pull_request.title
      end

      should "have 'number'" do
        assert_equal @pull_request_payload["number"], @pull_request.number
      end

      should "have 'username'" do
        assert_equal @pull_request_payload["user"]["login"], @pull_request.username
      end

      should "have 'body'" do
        assert_equal @pull_request_payload["body"], @pull_request.body
      end

      should "associate itself with all the commits" do
        pull_request.save!
        assert_equal %w{
          b3d156e4d4bb279e09cca0f31af8ea6e35d3df64
          baa3ef218a40f23fe542f98d8b8e60a2e8e0bff0},
          pull_request.commits.pluck(:sha)
      end
    end

    context "If there is already a local copy of that pull request," do
      setup do
        Github::PullRequest.create! { |pull|
          pull.merge_attributes @pull_request_payload }
      end

      context "when that pull request is created locally, it" do
        setup do
          @pull_request = Github::PullRequest.new { |pull|
            pull.merge_attributes @pull_request_payload }
        end

        should "be invalid" do
          refute pull_request.valid?, "Expected the second pull request to be invalid"
          assert_match /has already been taken/, pull_request.errors.full_messages.join(", ")
        end
      end
    end
  end


  context "Given a Pull Request" do
    setup do
      @project = Project.create!(
        name: "Test",
        slug: "test",
        version_control_name: "Git",
        extended_attributes: { "git_location" => Rails.root.join("test", "data", "bare_repo.git") })

      @pull_request = Github::PullRequest.create!(
        project: @project,
        number: 1,
        title: "Example Pull Request",
        repo: "test",
        url: "https://github.com/houston",
        username: "boblail",
        base_ref: "master",
        base_sha: "e0e4580f44317a084dd5142fef6b4144a4394819",
        head_ref: "divergent-branch",
        head_sha: "baa3ef218a40f23fe542f98d8b8e60a2e8e0bff0",
        labels: %w{old-label})
    end

    context "#add_label!" do
      should "add a label to the pull request" do
        @pull_request.add_label! "new-label"
        assert_equal %w{old-label new-label}, @pull_request.reload.labels
      end
    end

    context "#remove_label!" do
      should "remove a label from the pull request" do
        @pull_request.remove_label! "old-label"
        assert_equal [], @pull_request.reload.labels
      end
    end
  end


end
