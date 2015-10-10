module FeatureSupport

  def supports?(feature)
    features.member?(feature)
  end

  def supports_any?(*features)
    features.any?(&method(:supports?))
  end

  def supports_all?(*features)
    features.all?(&method(:supports?))
  end

end
