require "test_helper"
require "support/houston/adapters/mock_adapter"

class ProjectAdapterTest < ActiveSupport::TestCase
  attr_reader :project_klass


  context "has_adapter" do
    setup do
      @project_klass = Class.new(Project)
      @project_klass.has_adapter :MockAdapter
    end

    teardown do
      ProjectAdapter.send :remove_const, :MockAdapterConcern
    end

    should "add adapter methods to a project" do
      assert project_klass.ancestors.map(&:name).member? "ProjectAdapter::MockAdapterConcern"
    end

    should "raise an exception if called a second time" do
      assert_raises ArgumentError do
        project_klass.has_adapter :MockAdapter
      end
    end
  end


end
