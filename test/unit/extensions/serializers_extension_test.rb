require "test_helper"

class SerializersExtensionTest < ActiveSupport::TestCase


  context "Houston.serializers" do
    should "be an instance of Houston::Serializers" do
      assert_kind_of Houston::Serializers, Houston.serializers
    end
  end


  context "#add" do
    should "register a serializer for a certain kind of object" do
      n = UnserializableNumber.new(5)
      assert_raises Houston::Serializer::UnserializableError do
        serialize(n)
      end
      serializers << UnserializableNumberSerializer
      assert_equal "5", serialize(n)
    end
  end


private

  def serialize(object)
    Houston::Serializer.new(serializers).dump(object)
  end

  def serializers
    @serializers ||= Houston::Serializers.new
  end

  UnserializableNumber = Struct.new(:value)

  class UnserializableNumberSerializer
    def applies_to?(object)
      object.is_a? UnserializableNumber
    end

    def pack(object)
      object.value
    end
  end

end
