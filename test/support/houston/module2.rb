module Houston
  module Module2
    extend self

    class Engine < ::Rails::Engine
      isolate_namespace Houston::Module2
    end

    def dependencies
      [:module1]
    end

  end
end
