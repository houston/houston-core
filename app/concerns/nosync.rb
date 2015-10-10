module Nosync

  def nosync
    value = nosync?
    begin
      self.nosync = true
      yield
    ensure
      self.nosync = value
    end
  end

  def nosync=(value)
    @nosync = value
  end

  def nosync?
    !!@nosync
  end

end
