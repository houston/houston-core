require "test_helper"

class ProjectFeaturesExtensionTest < ActiveSupport::TestCase
  attr_reader :feature


  context "Houston.project_features" do
    should "be an instance of Houston::Extensions::Features" do
      assert_kind_of Houston::Extensions::Features, Houston.project_features
    end
  end


  context "Features#add" do
    setup do
      @feature = project_features.add(:google) { "https://google.com" }
    end

    should "add a feature to the array of features" do
      assert_equal "Google", project_features[:google].name
    end

    should "invoke the block when `path` is requested" do
      assert_equal "https://google.com", project_features[:google].path
    end

    should "add a feature that's accessible to everyone by default" do
      assert feature.permitted?(Ability.new(unprivileged_user))
    end

    should "let you chain an ability to the feature" do
      feature.ability { can?(:manange, :all) }

      assert feature.permitted?(Ability.new(privileged_user))
      refute feature.permitted?(Ability.new(unprivileged_user))
    end

    should "let you chain a different name to the feature" do
      feature.name("Yahoo!")

      assert_equal "Yahoo!", project_features[:google].name
    end

    context "#add_field" do
      setup do
        @field = feature.add_field("Material") do |f|
          f.select "test.material", %w{Aluminum Titanium Platinum}
        end
      end

      should "add a field to the array of fields" do
        assert_equal 1, feature.fields.length
        assert_equal "Material", feature.fields.first.label
      end

      should "invoke the block with a FormBuilder on render" do
        form_builder = Object.new
        mock(form_builder).select.with_any_args
        feature.fields.first.render(self, form_builder)
      end
    end
  end


private

  def project_features
    @project_features ||= Houston::Extensions::Features.new
  end

  def privileged_user
    @privileged_user ||= users(:boblail)
  end

  def unprivileged_user
    @unprivileged_user ||= create(:user)
  end

end
