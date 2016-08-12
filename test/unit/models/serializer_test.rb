require "test_helper"

class SerializerTest < ActiveSupport::TestCase


  should "serialize JSON literals conventionally" do
    assert_serializes(5, to: '5')
    assert_serializes("five", to: '"five"')
    assert_serializes(false, to: 'false')
    assert_serializes(nil, to: 'null')
  end

  should "let Oj serialize dates via iso8601" do
    assert_equal '{"^O":"Date","iso8601":"2016-07-15"}',
      dump(Date.new(2016, 7, 15))

    assert_equal '{"^O":"DateTime","iso8601":"2016-07-15T01:30:59+00:00"}',
      dump(DateTime.new(2016, 7, 15, 1, 30, 59.457))
  end

  should "let Oj serialize times" do
    assert_equal '{"^t":1468587630.542999999e59}',
      dump(Time.new(2016, 7, 15, 13, 1, 30, 59.457))
  end

  should "serialize Houston::ReadonlyHash like a hash" do
    assert_equal '{":x":5}', dump(Houston::ReadonlyHash.new(x: 5))
  end

  should "serialize ActiveSupport::TimeWithZone like a DateTime" do
    time = ActiveSupport::TimeZone["Mountain Time (US & Canada)"].now
    assert_equal '{"^O":"DateTime","iso8601":"' + time.iso8601 + '"}', dump(time)
  end

  should "serialize ActiveRecord objects by their raw attributes" do
    project = Project.create!(name: "Test", slug: "test")
    assert_serializes(project,
      like: /"class":"Project","attributes":{.*},"\^S":"Houston::ActiveRecordSerializer"/)
  end

  should "work even when you set a value" do
    project = Project.create!(name: "Test", slug: "test")
    project.updated_at = 1.week.after(project.updated_at) # ActiveSupport::TimeWithZone
    refute_match /"^o":"ActiveSupport::TimeWithZone"/, dump(x: project)
  end


private

  def assert_serializes(object, options={})
    serialized = dump(object)

    if expectation = options[:to]
      assert_equal expectation, serialized, "The object wasn't serialized as expected"
    end

    if expectation = options[:like]
      assert_match expectation, serialized, "The object wasn't serialized as expected"
    end

    assert_equal object, load(serialized), "The object wasn't deserialized as expected"
  end

  def load(string)
    Houston::Serializer.new.load(string)
  end

  def dump(object)
    Houston::Serializer.new.dump(object)
  end

end
