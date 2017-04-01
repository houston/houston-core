require "test_helper"

class LayoutTest < ActionDispatch::IntegrationTest

  teardown do
    Houston.layout.reset!
  end


  context "A runtime-defined meta tag" do
    setup do
      Houston.layout["application"].meta { tag "meta", name: "inserted-tag" }
    end

    should "be in every page's head" do
      get "/users/sign_in"
      assert_select 'head > meta[name="inserted-tag"]'
    end
  end


  context "A runtime-defined stylesheet tag" do
    setup do
      Houston.layout["application"].stylesheets { tag "meta", name: "inserted-tag" }
    end

    should "be in every page's head" do
      get "/users/sign_in"
      assert_select 'head > meta[name="inserted-tag"]'
    end
  end


  context "A runtime-defined footer tag" do
    setup do
      Houston.layout["application"].footers { tag "meta", name: "inserted-tag" }
    end

    should "be in every page's body" do
      get "/users/sign_in"
      assert_select 'body > meta[name="inserted-tag"]'
    end
  end


  context "A runtime-defined script tag" do
    setup do
      Houston.layout["application"].scripts { tag "meta", name: "inserted-tag" }
    end

    should "be in every page's body" do
      get "/users/sign_in"
      assert_select 'body > meta[name="inserted-tag"]'
    end
  end


end
