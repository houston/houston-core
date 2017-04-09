require "delegate"

module Houston
  module Permitted
    def permitted?(ability, *args)
      return true if @ability_block.nil?
      ability.instance_exec(*args, &@ability_block)
    end
  end

  module Render
    def render(view, *args)
      view.instance_exec(*args, &@render_block)
    end
  end

  module LinkTo
    def path(*args)
      @path_block.call(*args)
    end
  end

  module AbilityBlock
    def ability(&block)
      __getobj__.instance_variable_set :@ability_block, block
    end
  end
end

def Chain(*modules)
  object = modules.pop
  Class.new(SimpleDelegator).new(object).tap do |builder|
    modules.each do |mod|
      builder.extend mod
    end
  end
end
