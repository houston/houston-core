require "test_helper"


class PullRequestTest < ActiveSupport::TestCase
  attr_reader :project, :pull_request


  def setup
    stub(User).find_by_github_username { |*args| User.first }
  end


  context "Given GitHub API's description of a pull request" do
    setup do
      @project = Project.create!(
        name: "Test",
        slug: "test",
        version_control_name: "Git",
        props: {"git.location" => Rails.root.join("test", "data", "bare_repo.git").to_s})

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
        @pull_request = Github::PullRequest.create! { |pull|
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



      context "when the pull request is synchronized," do
        context "and base_sha changes, it" do
          setup do
            pull_request.merge_attributes(
              "user" => {},
              "title" => "Divergent Branch",
              "body" => "This is the description of the pull request",
              "base" => { "sha" => "a5c551d52bb0bb8a702f70879ac9caeb12a721fc" },
              "head" => { "sha" => "baa3ef218a40f23fe542f98d8b8e60a2e8e0bff0" })
          end

          should "associate itself with all the commits again" do
            mock(pull_request.project.commits).between(
              "a5c551d52bb0bb8a702f70879ac9caeb12a721fc",
              "baa3ef218a40f23fe542f98d8b8e60a2e8e0bff0").once.returns([])
            pull_request.save!
          end

          should "fire 'github:pull:synchronize'" do
            assert_triggered "github:pull:synchronize" do
              pull_request.save!
            end
          end
        end

        context "and head_sha changes, it" do
          setup do
            pull_request.merge_attributes(
              "user" => {},
              "title" => "Divergent Branch",
              "body" => "This is the description of the pull request",
              "base" => { "sha" => "e0e4580f44317a084dd5142fef6b4144a4394819" },
              "head" => { "sha" => "a5c551d52bb0bb8a702f70879ac9caeb12a721fc" })
          end

          should "associate itself with all the commits again" do
            mock(pull_request.project.commits).between(
              "e0e4580f44317a084dd5142fef6b4144a4394819",
              "a5c551d52bb0bb8a702f70879ac9caeb12a721fc").once.returns([])
            pull_request.save!
          end

          should "fire 'github:pull:synchronize'" do
            assert_triggered "github:pull:synchronize" do
              pull_request.save!
            end
          end
        end

        context "and neither base_sha nor head_sha changes, it" do
          setup do
            pull_request.merge_attributes(
              "user" => {},
              "title" => "Divergent Branch",
              "body" => "This is the description of the pull request",
              "base" => { "sha" => "e0e4580f44317a084dd5142fef6b4144a4394819" },
              "head" => { "sha" => "baa3ef218a40f23fe542f98d8b8e60a2e8e0bff0" })
          end

          should "not associate itself with all the commits again" do
            mock(pull_request.project.commits).between.never
            pull_request.save!
          end
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
        props: {"git.location" => Rails.root.join("test", "data", "bare_repo.git").to_s})

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
        labels: [{"name" => "old-label"}])
    end

    context "#add_label!" do
      should "add a label to the pull request" do
        @pull_request.add_label!("name" => "new-label")
        assert_equal [{"name" => "old-label"}, {"name" => "new-label"}], @pull_request.reload.labels
      end
    end

    context "#remove_label!" do
      should "remove a label from the pull request" do
        @pull_request.remove_label!("name" => "old-label")
        assert_equal [], @pull_request.reload.labels
      end
    end
  end


end
