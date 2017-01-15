require "houston/adapters"

Houston::Adapters.define_adapter_namespace "TestAdapter"

module Houston
  module Adapters
    module TestAdapter
      class NoneAdapter
        def self.errors_with_parameters(*args); {}; end
        def self.build(*args); nil; end
        def self.parameters; []; end
      end

      class MockAdapter
        def self.errors_with_parameters(*args); {}; end
        def self.build(*args); nil; end
        def self.parameters; []; end
      end
    end
  end
end
