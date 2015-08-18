require "test_helper"


class PostReceivePayloadTest < ActiveSupport::TestCase

  should "be able to parse JSON payloads from GitHub" do
    assert_equal "0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c",
      PostReceivePayload.new(github_push_event_payload).commit
  end

private

  def github_push_event_payload
    @github_push_event_payload ||= MultiJson.load(
      File.read(
        Rails.root.join("test/data/github_push_event_payload.json")))
  end

end
