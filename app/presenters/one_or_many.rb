class OneOrMany < SimpleDelegator
  
  delegate :is_a?, to: :__getobj__
  
  def map(&block)
    if __getobj__.respond_to?(:map)
      __getobj__.map(&block)
    else
      yield __getobj__
    end
  end
  
end
