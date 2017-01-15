module ProjectAdapter


  def adapters
    @adapters ||= {}
  end


  def has_adapter(*adapter_namespaces)
    adapter_namespaces.each do |adapter_namespace|
      adapter_module = Houston::Adapters[adapter_namespace]
      raise ArgumentError, "#{adapter_module} should respond to `adapters`" unless adapter_module.respond_to?(:adapters)
      raise ArgumentError, "#{adapter_module} should respond to `adapter`" unless adapter_module.respond_to?(:adapter)
      raise ArgumentError, "#{adapter_namespace} has already been defined" if adapters[adapter_module.name]

      adapter = Adapter.new(self, adapter_module)
      adapters[adapter_module.name] = adapter
      adapter.define_methods!
    end
  end


  class Adapter

    def initialize(model, adapter_module)
      @model          = model
      @namespace      = adapter_module
      @name           = adapter_module.name
      @attribute_name = name.demodulize.underscore
    end

    attr_reader :model, :namespace, :name, :attribute_name

    def title
      name.demodulize.titleize
    end

    def validation_method
      :"#{attribute_name}_configuration_is_valid"
    end

    def before_update_method
      :"#{attribute_name}_before_update"
    end

    def adapter_method
      :"#{attribute_name}_adapter"
    end

    def params_method
      :"parameters_for_#{attribute_name}_adapter"
    end

    def concern_name
      :"#{name.demodulize}Concern"
    end

    def define_methods!
      concern = ProjectAdapter.const_set(concern_name, Module.new)
      concern.extend ActiveSupport::Concern

      class_methods = concern.const_set(:ClassMethods, Module.new)
      class_methods.module_eval <<-RUBY, __FILE__ , __LINE__ + 1
        def with_#{attribute_name}
          where arel_table[:#{attribute_name}_name].not_eq("None")
        end
      RUBY

      concern.module_eval <<-RUBY, __FILE__ , __LINE__ + 1
        included do
          validate :#{validation_method}
          before_update :#{before_update_method}
        end

        def has_#{attribute_name}?
          #{attribute_name}_name != "None"
        end

        def #{validation_method}
          #{adapter_method}.errors_with_parameters(self, *#{params_method}.values).each do |attribute, messages|
            errors.add(attribute, messages) if messages.any?
          end
        end

        def #{before_update_method}
          return true unless #{attribute_name}.respond_to?(:before_update)
          #{attribute_name}.before_update(self)
        end

        def #{attribute_name}
          @#{attribute_name} ||= #{adapter_method}
              .build(self, *#{params_method}.values)
              .extend(FeatureSupport)
        end

        def #{params_method}
          #{adapter_method}.parameters.each_with_object({}) do |parameter, hash|
            hash[parameter] = props[parameter.to_s]
          end
        end

        def #{adapter_method}
          #{namespace}.adapter(#{attribute_name}_name)
        end
      RUBY

      model.send :include, concern
    end

  end


end
