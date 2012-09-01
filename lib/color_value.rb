class ColorValue
  
  def initialize(hex)
    @hex = hex
  end
  
  def to_s
    @hex
  end
  
  def rgb
    "rgb(#{@hex.scan(/../).map { |s| s.to_i(16) }.join(", ")})"
  end
  
end
