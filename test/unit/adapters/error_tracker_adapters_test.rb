require "test_helper"
require "support/houston/adapters/error_tracker/mock_adapter"

class ErrorTrackerAdatersApiTest < ActiveSupport::TestCase

  test "Houston::Adapters::ErrorTracker.adapters finds all available adapters" do
    assert_equal %w{None Errbit Mock}, Houston::Adapters::ErrorTracker.adapters
  end

  apps = []
  Houston::Adapters::ErrorTracker.adapters.each do |adapter_name|
    adapter = Houston::Adapters::ErrorTracker.adapter(adapter_name)
    apps << adapter.build(Project.new, 1)

    test "#{adapter.name} responds to the ErrorTracker::Adapter interface" do
      assert_respond_to adapter, :errors_with_parameters
      assert_respond_to adapter, :build
      assert_respond_to adapter, :parameters

      assert_respond_to adapter, :problems_during
      assert_respond_to adapter, :notices_during
    end
  end

  apps.uniq.each do |app|
    test "#{app.class.name} responds to the ErrorTracker::App interface" do
      assert_respond_to app, :project_url
      assert_respond_to app, :error_url

      assert_respond_to app, :problems_during
      assert_respond_to app, :open_problems
      assert_respond_to app, :resolve!
    end
  end

end
