module ProjectAdapter
  
  
  def adapters
    @adapters ||= {}
  end
  
  
  def has_adapter(adapter_module, options={})
    raise ArgumentError, "#{adapter_module} should respond to `adapters`" unless adapter_module.respond_to?(:adapters)
    raise ArgumentError, "#{adapter_module} should respond to `adapter`" unless adapter_module.respond_to?(:adapter)
    raise ArgumentError, "#{adapter_module} should respond to `arguments`" unless adapter_module.respond_to?(:arguments)
    
    adapter = Adapter.new(self, adapter_module, options)
    adapters[adapter.name] = adapter
    
    adapter.define_methods!
    
    validate adapter.validation_method
  end
  
  
  class Adapter
    
    def initialize(model, adapter_module, options={})
      @model          = model
      @adapter_module = adapter_module
      @name           = adapter_module.name
      @attribute_name = name.demodulize.underscore
      @arguments      = adapter_module.arguments
      @options        = options
      @parameters     = options.values
      
      missing_args    = arguments - options.keys
      raise ArgumentError, "#{adapter_module} adapters accept #{arguments.length} arguments: #{arguments.to_sentence}, but #{model} did not define #{missing_args.to_sentence}" unless missing_args.empty?
    end
    
    attr_reader :model, :adapter_module, :name, :attribute_name, :arguments, :parameters
    
    def validation_method
      :"#{attribute_name}_configuration_is_valid"
    end
    
    def name_of_argument(argument)
      @options[argument]
    end
    
    def define_methods!
      model.module_eval <<-RUBY
        def self.with_#{attribute_name}
          where arel_table[:#{attribute_name}_name].not_eq("None")
        end
        
        def has_#{attribute_name}?
          #{attribute_name}_name != "None"
        end
        
        def #{validation_method}
          #{attribute_name}_adapter.errors_with_parameters(#{parameters.join(", ")}).each do |argument, messages|
            next if messages.empty?
            attribute = self.class.adapters["#{name}"].name_of_argument(argument)
            errors.add(attribute, messages)
          end
        end
        
        def #{attribute_name}
          @#{attribute_name} ||= #{attribute_name}_adapter.build(#{parameters.join(", ")})
        end
        
        def #{attribute_name}_adapter
          #{adapter_module}.adapter(#{attribute_name}_name)
        end
      RUBY
    end
    
  end
  
  
end
