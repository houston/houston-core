require "test_helper"
require "support/houston/adapters/ci_server/mock_adapter"

class TestRunComparerTest < ActiveSupport::TestCase
  attr_reader :project, :tests, :tr1, :tr2

  context "Given two runs of a suite of tests," do
    setup do
      @project = create(:project)
      @tests = project.tests.create [
        {suite: "CommitTest", name:	"should extract a clean message from a commit"},
        {suite: "CommitTest", name: "should extract an array of tags from the front of a commit"},
        {suite: "CommitTest", name: "should extract an array of tickets from the end of a commit"},
        {suite: "CommitTest", name: "should extract extra attributes from a commit" }]
      @tr1 = TestRun.create!(project: project, sha: "a")
      @tr2 = TestRun.create!(project: project, sha: "b")
    end

    context "when both runs get the same result for a test, it" do
      setup do
        tr1.test_results.create [{test_id: tests[0].id, status: "pass"}]
        tr2.test_results.create [{test_id: tests[0].id, status: "pass"}]
      end

      should "mark the latter as not-different" do
        run_comparer!
        assert_equal false, tr2.test_results[0].reload.different
      end

      should "mark the latter as not-new" do
        run_comparer!
        assert_equal false, tr2.test_results[0].reload.new_test
      end
    end

    context "when the two runs get different results for a test, it" do
      setup do
        tr1.test_results.create [{test_id: tests[0].id, status: "fail"}]
        tr2.test_results.create [{test_id: tests[0].id, status: "pass"}]
      end

      should "mark the latter as different" do
        run_comparer!
        assert_equal true, tr2.test_results[0].reload.different
      end

      should "mark the latter as not-new" do
        run_comparer!
        assert_equal false, tr2.test_results[0].reload.new_test
      end
    end

    context "when the second run has a test that the first doesn't, it" do
      setup do
        tr1.result = "pass"
        tr2.test_results.create [{test_id: tests[0].id, status: "pass"}]
      end

      should "mark the latter as not-different" do
        run_comparer!
        assert_equal false, tr2.test_results[0].reload.different
      end

      should "mark the latter as new" do
        run_comparer!
        assert_equal true, tr2.test_results[0].reload.new_test
      end
    end

    context "when the first run errored out, it" do
      setup do
        tr1.result = "error"
        tr2.test_results.create [{test_id: tests[0].id, status: "pass"}]
      end

      should "not mark the latter as new" do
        run_comparer!
        assert_equal nil, tr2.test_results[0].reload.new_test
      end
    end

    context "after comparing them, it" do
      setup do
        tr1.test_results.create [{test_id: tests[0].id, status: "pass"}]
        tr2.test_results.create [{test_id: tests[0].id, status: "pass"}]
      end

      should "mark the second test_run as compared" do
        run_comparer!
        assert tr2.reload.compared?
      end

      should "fire 'test_run:compared'" do
        assert_triggered "test_run:compared" do
          run_comparer!
        end
      end
    end
  end


private

  def run_comparer!
    TestRunComparer.compare!(tr1, tr2)
  end

end
