module Houston
  module Adapters
    class << self

      def each
        constants.each do |name|
          yield name, name_to_path(name)
        end
      end

      alias :[] :const_get

      def define_adapter_namespace(name)
        namespace = ::Module.new
        const_set name, namespace

        pathname = name_to_path(name)
        adapters_paths = File.join(File.dirname(caller[0]), "#{pathname}/*_adapter.rb")
        Dir[adapters_paths].each(&method(:require))

        def namespace.adapters
          constants
            .select { |sym| sym =~ /Adapter$/ }
            .map { |sym| sym[/^.*(?=Adapter)/] }
            .sort_by { |name| name == "None" ? "" : name }
        end

        def namespace.adapter(name)
          const_get "#{name}Adapter"
        end

        def namespace.adapter?(name)
          adapters.map(&:downcase).member?(name.to_s.downcase)
        end
      end

    private

      def name_to_path(name)
        # Copied and simplified from ActiveSupport::Inflector.underscore
        name.to_s
          .gsub(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
          .gsub(/([a-z\d])([A-Z])/,'\1_\2')
          .downcase
      end

    end
  end
end

require "houston/adapters/ticket_tracker"
require "houston/adapters/version_control"
