module Houston
  module CI
    
    class Error < StandardError
    end
    
    class NotConfiguredError < ::Houston::CI::Error
    end
    
    class NotFoundError < ::Houston::CI::Error
    end
    
  end
end
