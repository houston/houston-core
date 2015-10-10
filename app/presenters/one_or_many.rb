class OneOrMany < SimpleDelegator

  delegate :is_a?, to: :__getobj__

  def map(&block)
    if __getobj__.respond_to?(:map)
      __getobj__.map(&block)
    else
      yield __getobj__
    end
  end

  def select(&block)
    if __getobj__.respond_to?(:select)
      __getobj__.select(&block)
    else
      return [] unless yield __getobj__
      self
    end
  end

end
