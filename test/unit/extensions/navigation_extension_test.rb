require "test_helper"

class NavigationExtensionTest < ActiveSupport::TestCase
  attr_reader :link


  context "Houston.navigation" do
    should "be an instance of Houston::Navigation" do
      assert_kind_of Houston::Navigation, Houston.navigation
    end
  end


  context "Navigation#add_link" do
    setup do
      @link = navigation.add_link(:google) { "https://google.com" }
    end

    should "add a link to the array of links" do
      assert_equal 1, navigation.links.length
      assert_equal :google, navigation.links.first.slug
      assert_equal "Google", navigation.links.first.name
    end

    should "invoke the block when `path` is requested" do
      assert_equal "https://google.com", navigation.links.first.path
    end

    should "add a link that's accessible to everyone by default" do
      assert link.permitted?(Ability.new(unprivileged_user))
    end

    should "let you chain an ability to the link" do
      link.ability { can?(:manange, :all) }

      assert link.permitted?(Ability.new(privileged_user))
      refute link.permitted?(Ability.new(unprivileged_user))
    end

    should "let you chain a different name to the link" do
      link.name("Yahoo!")

      assert_equal "Yahoo!", navigation.links.first.name
    end
  end


private

  def navigation
    @navigation ||= Houston::Navigation.new
  end

  def privileged_user
    @privileged_user ||= users(:boblail)
  end

  def unprivileged_user
    @unprivileged_user ||= create(:user)
  end

end
