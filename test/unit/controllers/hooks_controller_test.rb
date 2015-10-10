require "test_helper"

class HooksControllerTest < ActionController::TestCase


  context "When GitHub posts a ping event, it" do
    setup do
      request.headers["X-Github-Event"] = "ping"
    end

    should "respond with success" do
      post :github, hook: {}
      assert_response :success
    end
  end


  context "When GitHub posts a pull_request event, it" do
    setup do
      request.headers["X-Github-Event"] = "pull_request"
    end

    should "respond with success" do
      stub.instance_of(Github::PullRequestEvent).process!
      post :github, hook: github_pull_request_event_payload
      assert_response :success
    end

    should "close a GitHub::PullRequest when the action is \"closed\"" do
      mock(Github::PullRequest).close!(a_pull_request)
      post :github, hook: github_pull_request_event_payload(action: "closed")
    end

    should "create or update a GitHub::PullRequest when the action is not \"closed\"" do
      mock(Github::PullRequest).upsert!(a_pull_request)
      post :github, hook: github_pull_request_event_payload
    end
  end


  context "When GitHub posts a push event, it" do
    setup do
      request.headers["X-Github-Event"] = "push"
    end

    should "respond with success" do
      stub.instance_of(Github::PostReceiveEvent).process!
      post :github, hook: {}
      assert_response :success
    end

    should "trigger a `hooks:post_receive` event for the project" do
      project = create(:project, slug: "public-repo")
      expected_payload = hash_including(github_push_event_payload.slice("before", "after"))
      mock(Houston.observer).fire("hooks:post_receive", project, expected_payload)
      post :github, hook: github_push_event_payload
    end
  end


  context "When GitHub posts some other event, it" do
    setup do
      request.headers["X-Github-Event"] = "gollum"
    end

    should "respond with not_found" do
      post :github, hook: {}
      assert_response :not_found
    end
  end


private

  def github_push_event_payload
    @github_push_event_payload ||= MultiJson.load(
      File.read(
        Rails.root.join("test/data/github_push_event_payload.json")))
  end

  def github_pull_request_event_payload(options={})
    { action: "opened",
      pull_request: a_pull_request }.merge(options)
  end

  def a_pull_request
    { "id" => "42766810",
      "html_url" => "https://github.com/concordia-publishing-house/test/pull/1",
      "number" => "1",
      "state" => "open",
      "locked" => false,
      "title" => "[skip] Put something in the README (1m)",
      "user" => { "login" => "boblail" },
      "body" => "",
      "created_at" => "2015-08-19T01:03:43Z",
      "updated_at" => "2015-08-19T01:03:43Z",
      "closed_at" => nil,
      "merged_at" => nil,
      "merge_commit_sha" => nil,
      "assignee" => nil,
      "milestone" => nil,
      "head" => {
        "label" => "concordia-publishing-house:branch",
        "ref" => "branch",
        "sha" => "4e44fa43a06580b07820e1947b1c209880de1f84",
        "repo"=>{
          "id" => "41005299",
          "name" => "test",
          "full_name" => "concordia-publishing-house/test",
          "private" => false } },
      "base" => {
        "label" => "concordia-publishing-house:master",
        "ref" => "master",
        "sha" => "f478de5e6b8e42882b139a0b2cee144d0a1b90a4",
        "repo"=>{
          "id" => "41005299",
          "name" => "test",
          "full_name" => "concordia-publishing-house/test",
          "private" => false } },
      "merged" => false,
      "mergeable" => nil }
  end

end
