require "test_helper"

class ViewExtensionTest < ActiveSupport::TestCase
  attr_reader :column, :field

  context "Houston.view" do
    should "be an instance of Houston::Extensions::Views" do
      assert_kind_of Houston::Extensions::Views, Houston.view
    end
  end

  context 'Houston.view["anything"]' do
    should "be an instance of Houston::View" do
      assert_kind_of Houston::Extensions::View, Houston.view["anything"]
    end

    should "support `has` as a shortcut for extend" do
      view = views["test"].has :Table
      assert_kind_of Houston::Extensions::HasTable, view
    end
  end


  context "HasTable#add_column" do
    setup do
      views["widgets"].has :Table
      @column = views["widgets"].add_column("Rotation") { 45 }
    end

    should "add a column to the array of columns" do
      assert_equal 1, views["widgets"].columns.length
      assert_equal "Rotation", views["widgets"].columns.first.name
    end

    should "invoke the block on render" do
      assert_equal 45, views["widgets"].columns.first.render(self)
    end

    should "add a column that's accessible to everyone by default" do
      assert column.permitted?(Ability.new(unprivileged_user))
    end

    should "let you chain an ability to the column" do
      column.ability { can?(:manange, :all) }

      assert column.permitted?(Ability.new(privileged_user))
      refute column.permitted?(Ability.new(unprivileged_user))
    end
  end


  context "HasForm#add_field" do
    setup do
      views["widgets"].has :Form
      @field = views["widgets"].add_field("Material") do |f|
        f.select "test.material", %w{Aluminum Titanium Platinum}
      end
    end

    should "add a field to the array of fields" do
      assert_equal 1, views["widgets"].fields.length
      assert_equal "Material", views["widgets"].fields.first.label
    end

    should "invoke the block with a FormBuilder on render" do
      form_builder = Object.new
      mock(form_builder).select.with_any_args
      views["widgets"].fields.first.render(self, form_builder)
    end

    should "add a field that's accessible to everyone by default" do
      assert field.permitted?(Ability.new(unprivileged_user))
    end

    should "let you chain an ability to the field" do
      field.ability { can?(:manange, :all) }

      assert field.permitted?(Ability.new(privileged_user))
      refute field.permitted?(Ability.new(unprivileged_user))
    end
  end


private

  def views
    @views ||= Houston::Extensions::Views.new
  end

  def privileged_user
    @privileged_user ||= users(:boblail)
  end

  def unprivileged_user
    @unprivileged_user ||= create(:user)
  end

end
