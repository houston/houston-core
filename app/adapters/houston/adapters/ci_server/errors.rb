module Houston
  module Adapters
    module CIServer

      class Error < StandardError
      end

      class NotConfiguredError < ::Houston::Adapters::CIServer::Error
      end

      class NotFoundError < ::Houston::Adapters::CIServer::Error
      end

    end
  end
end
