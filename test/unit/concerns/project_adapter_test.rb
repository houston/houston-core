require "test_helper"
require "support/houston/adapters/test_adapter"

class ProjectAdapterTest < ActiveSupport::TestCase
  attr_reader :project_klass


  context "has_adapter" do
    setup do
      @project_klass = Class.new(Project)
      @project_klass.has_adapter :TestAdapter
    end

    teardown do
      ProjectAdapter.send :remove_const, :TestAdapterConcern
    end

    should "add adapter methods to a project" do
      assert project_klass.ancestors.map(&:name).member? "ProjectAdapter::TestAdapterConcern"
    end

    should "raise an exception if called a second time" do
      assert_raises ArgumentError do
        project_klass.has_adapter :TestAdapter
      end
    end


    context "Concern:" do
      context "test_adapter_name" do
        should "be an alias for props->'adapter.testAdapter'" do
          project = project_klass.new(name: "Mock", slug: "mock", props: { "adapter.testAdapter" => "Mock" })
          assert_equal "Mock", project.test_adapter_name
        end
      end

      context "with_test_adapter" do
        setup do
          project_klass.create!(name: "None", slug: "none", props: { "adapter.testAdapter" => "None" })
          project_klass.create!(name: "Mock", slug: "mock", props: { "adapter.testAdapter" => "Mock" })
        end

        should "find all projects where the selected adapter is not 'None'" do
          assert_equal %w{mock}, project_klass.with_test_adapter.pluck(:slug)
        end

        should "find all projects with a specified adapter name" do
          assert_equal %w{mock}, project_klass.with_test_adapter("Mock").pluck(:slug)
          assert_equal %w{none}, project_klass.with_test_adapter("None").pluck(:slug)
        end
      end
    end
  end


end
