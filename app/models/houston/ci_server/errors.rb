module Houston
  module CIServer
    
    class Error < StandardError
    end
    
    class NotConfiguredError < ::Houston::CIServer::Error
    end
    
    class NotFoundError < ::Houston::CIServer::Error
    end
    
  end
end
