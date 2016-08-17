module Houston
  class ActiveRecordSerializer

    def applies_to?(object)
      object.is_a?(ActiveRecord::Base)
    end

    def pack(record)
      model = record.class
      normal_attributes = record.attributes.each_with_object({}) do |(attribute, value), attributes|
        column = model.column_for_attribute(attribute)
        attributes[attribute] = model.connection.type_cast_from_column(column, value)
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
