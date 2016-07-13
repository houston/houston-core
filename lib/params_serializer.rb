require "oj_serializer"

class ParamsSerializer < OjSerializer
  class UnserializableError < ArgumentError; end

  def load(string)
    object = super(string || "{}")
    object.each do |key, value|
      object[key] = load_active_record(value) if value.is_a?(Hash) && value.key?("^R")
    end
  end

  def dump(object)
    object = {} if object.nil?
    object = object.to_h if !object.is_a?(Hash) && object.respond_to?(:to_h)
    raise ArgumentError, "params must be a Hash, but it is a #{object.class}" unless object.is_a?(Hash)

    object = object.dup
    object.each do |key, value|
      object[key] = value = dump_active_record(value) if value.is_a?(ActiveRecord::Base)
      assert_serializable!(value)
    end

    super object
  end

private

  def dump_active_record(record)
    model = record.class
    normal_attributes = record.attributes.each_with_object({}) do |(attribute, value), attributes|
      attributes[attribute] = model.column_for_attribute(attribute).type_cast_for_database(value)
    end
    { "^R" => model.name, "attributes" => normal_attributes }
  end

  def load_active_record(attributes)
    klass, attributes = attributes.values_at("^R", "attributes")
    klass.constantize.instantiate(attributes)
  end

  def assert_serializable!(value)
    return if SERIALIZABLE_TYPES.member? value.class.name

    if value.class == Array
      value.each do |value|
        assert_serializable!(value)
      end
    elsif value.class == Hash
      value.each do |key, value|
        unless key.is_a?(String) || key.is_a?(Symbol)
          raise UnserializableError, "Hash keys must be either strings or symbols"
        end
        assert_serializable!(value)
      end
    else
      raise UnserializableError, "Unable to serialize a #{value.class} (#{value.inspect})"
    end
  end

  SERIALIZABLE_TYPES = %w{
    BigDecimal
    Date
    DateTime
    FalseClass
    Fixnum
    Float
    NilClass
    String
    Symbol
    Time
    TrueClass
  }.freeze

end
