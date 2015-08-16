require "test_helper"

class HooksControllerTest < ActionController::TestCase


  context "When GitHub posts a ping event, it" do
    setup do
      request.headers["X-Github-Event"] = "ping"
    end

    should "respond with success" do
      post :github
      assert_response :success
    end
  end


  context "When GitHub posts a pull_request event, it" do
    setup do
      request.headers["X-Github-Event"] = "pull_request"
    end

    should "process it with Github::PullRequestEvent" do
      mock.instance_of(Github::PullRequestEvent).process!
      post :github
    end

    should "respond with success" do
      stub.instance_of(Github::PullRequestEvent).process!
      post :github
      assert_response :success
    end
  end


  context "When GitHub posts a push event, it" do
    setup do
      request.headers["X-Github-Event"] = "push"
    end

    should "process it with Github::PostReceiveEvent" do
      mock.instance_of(Github::PostReceiveEvent).process!
      post :github
    end

    should "respond with success" do
      stub.instance_of(Github::PostReceiveEvent).process!
      post :github
      assert_response :success
    end

    should "trigger a `hooks:post_receive` event for the project" do
      project = create(:project, slug: "public-repo")
      expected_payload = hash_including(github_push_event_payload.slice("before", "after"))
      mock(Houston.observer).fire("hooks:post_receive", project, expected_payload)
      post :github, github_push_event_payload
    end
  end


  context "When GitHub posts some other event, it" do
    setup do
      request.headers["X-Github-Event"] = "gollum"
    end

    should "respond with not_found" do
      post :github
      assert_response :not_found
    end
  end


private

  def github_push_event_payload
    @github_push_event_payload ||= MultiJson.load(
      File.read(
        Rails.root.join("test/data/github_push_event_payload.json")))
  end

end
