require "test_helper"

class LayoutExtensionTest < ActiveSupport::TestCase


  context "Houston.layout" do
    should "be an instance of Houston::Layout" do
      assert_kind_of Houston::Layout, Houston.layout
    end
  end

  context 'Houston.layout["application"]' do
    should "be an instance of Houston::Layout::ExtensionDsl" do
      assert_kind_of Houston::Layout::ExtensionDsl, Houston.layout["application"]
    end
  end

  context 'Houston.layout["anything"]' do
    should "raise an ArgumentError" do
      assert_raises ArgumentError do
        Houston.layout["anything"]
      end
    end
  end



  context 'Houston.layout.meta["application"]' do
    setup do
      layout["application"].meta { tag "meta", name: "inserted-tag" }
    end

    should "add a meta tag to the application layout" do
      assert_equal 1, layout.extensions_by_layout["application"].meta.length
    end

    should "not add a meta tag to the dashboard layout" do
      assert_equal 0, layout.extensions_by_layout["dashboard"].meta.length
    end
  end

  context 'Houston.layout.meta["dashboard"]' do
    setup do
      layout["dashboard"].meta { tag "meta", name: "inserted-tag" }
    end

    should "add a meta tag to the dashboard layout" do
      assert_equal 1, layout.extensions_by_layout["dashboard"].meta.length
    end

    should "not add a meta tag to the application layout" do
      assert_equal 0, layout.extensions_by_layout["application"].meta.length
    end
  end

  context 'Houston.layout.meta' do
    setup do
      layout.meta { tag "meta", name: "inserted-tag" }
    end

    should "add a meta tag to both layouts" do
      assert_equal 1, layout.extensions_by_layout["application"].meta.length
      assert_equal 1, layout.extensions_by_layout["dashboard"].meta.length
    end
  end


private

  def layout
    @layout ||= Houston::Layout.new
  end

end
