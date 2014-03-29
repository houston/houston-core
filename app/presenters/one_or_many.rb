class OneOrMany
  
  def initialize(one_or_many)
    @one_or_many = one_or_many
  end
  
  def load
    @one_or_many.load if @one_or_many.respond_to?(:load)
    self
  end
  
  def map(&block)
    if @one_or_many.respond_to?(:map)
      @one_or_many.map(&block)
    else
      yield @one_or_many
    end
  end
  
end
