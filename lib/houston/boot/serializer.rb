require "oj"

Oj.register_odd(Date, Date, :iso8601, :iso8601)
Oj.register_odd(DateTime, DateTime, :iso8601, :iso8601)

module Houston
  class Serializer
    class UnserializableError < ArgumentError; end

    def initialize(serializers=Houston.serializers)
      @serializers = serializers
    end

    def load(string)
      begin
        object = Oj.load(string, nilnil: true, auto_define: false)
      rescue ArgumentError
        raise ArgumentError, "#{string.inspect} is the wrong type; it should be a String or NilClass"
      end
      unpack object
    end

    def dump(object)
      Oj.dump pack(object)
    end

    def assert_serializable!(object)
      pack(object); nil
    end

  private
    attr_reader :serializers

    def unpack(object)
      if object.is_a?(Array)
        object.map { |item| unpack(item) }
      elsif object.is_a?(Hash)
        object = object.each_with_object({}) { |(key, value), new_object| new_object[key] = unpack(value) }
        serializer = object["^S"]
        object = serializer.constantize.new.unpack(object) if serializer
        object
      else
        object
      end
    end

    def pack(object)
      case object
      when Array
        object.map { |item| pack(item) }
      when Hash
        object.each_with_object({}) do |(key, value), new_object|
          unless key.is_a?(String) || key.is_a?(Symbol)
            raise UnserializableError, "Hash keys must be either strings or symbols"
          end
          new_object[key] = pack(value)
        end
      when ActionController::Parameters
        pack object.to_h
      when ActiveSupport::TimeWithZone
        object.to_datetime
      when ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array::Data
        pack object.values
      when *SERIALIZABLE_TYPES
        object
      else
        serializers.each do |serializer|
          next unless serializer.applies_to?(object)
          packed_object = serializer.pack(object)
          packed_object["^S"] = serializer.class.name if serializer.respond_to?(:unpack)
          return pack(packed_object)
        end

        raise UnserializableError, <<-STR.squish
          Unable to serialize a #{object.class} (#{object.inspect})
          You can add a serializer for it with `Houston.add_serializer`
        STR
      end
    end

    SERIALIZABLE_TYPES = [
      BigDecimal,
      Date,
      DateTime,
      FalseClass,
      Float,
      Integer,
      NilClass,
      String,
      Symbol,
      Time,
      TrueClass
    ].freeze

  end
end
