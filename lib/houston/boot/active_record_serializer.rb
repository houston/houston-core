module Houston
  class ActiveRecordSerializer

    def applies_to?(object)
      object.is_a?(ActiveRecord::Base)
    end

    def pack(record)
      model = record.class
      normal_attributes = record.attributes.each_with_object({}) do |(attribute, value), attributes|
        attributes[attribute] = value.nil? ? nil :
          model.type_for_attribute(attribute).type_cast_for_schema(value)
      end
      { "class" => model.name, "attributes" => normal_attributes }
    end

    def unpack(object)
      klass, attributes = object.values_at("class", "attributes")
      klass.constantize.instantiate(attributes)
    end

  end
end

Houston.add_serializer Houston::ActiveRecordSerializer.new
