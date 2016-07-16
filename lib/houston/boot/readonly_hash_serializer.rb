module Houston
  class ReadonlyHashSerializer

    def applies_to?(object)
      object.is_a?(Houston::ReadonlyHash)
    end

    def pack(object)
      object.to_h
    end

  end
end

Houston.add_serializer Houston::ReadonlyHashSerializer.new
