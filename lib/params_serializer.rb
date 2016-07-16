require "houston/boot/serializer"

module Houston
  class ParamsSerializer < Serializer

    def load(string)
      super(string || "{}")
    end

    def dump(object)
      object = {} if object.nil?
      object = object.to_h if !object.is_a?(Hash) && object.respond_to?(:to_h)
      raise ArgumentError, "params must be a Hash, but it is a #{object.class}" unless object.is_a?(Hash)
      super object
    end

  end
end
