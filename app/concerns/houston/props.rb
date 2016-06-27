module Houston
  module Props
    extend ActiveSupport::Concern

    VALID_PROP_NAME = /\A[a-z0-9]+(?:\.[a-z0-9_\-]+)+\Z/i.freeze

    def self.valid_prop_name!(prop_name)
      return if prop_name =~ VALID_PROP_NAME
      raise ArgumentError, "#{prop_name.inspect} can only contain word-characters, hyphens, and must contain at least one period"
    end


    module ClassMethods
      def with_prop(prop_name, value)
        Houston::Props.valid_prop_name!(prop_name)
        where(["props->>? = ?", prop_name, value])
      end

      def find_by_prop(prop_name, value)
        result = with_prop(prop_name, value).limit(1).first

        if !result && block_given?
          result = yield value
          if result
            result.update_prop! prop_name, value
          else
            Rails.logger.info "\e[34mUnable to identify a #{name} where \e[1m#{prop_name}\e[0;34m=\e[1m#{value}\e[0m"
          end
        end

        result
      end
    end


    def get_prop(prop_name)
      Houston::Props.valid_prop_name!(prop_name)
      value = props[prop_name]

      if !value && block_given?
        value = yield self
        if value
          update_prop! prop_name, value
        else
          Rails.logger.info "\e[34mUnable to identify \e[1m#{prop_name}\e[0;34m for #{inspect}\e[0m"
        end
      end

      value
    end

    def update_prop!(prop_name, value)
      update_column :props, props.merge!(prop_name => value)
    end

    def props
      PropsIndexer.new(self, super)
    end

  private

    class PropsIndexer
      def initialize(record, hash)
        @record = record
        @hash = hash
      end

      delegate :[], :fetch, :each_pair, :key?, to: :@hash

      def []=(prop_name, value)
        merge!(prop_name => value)
      end

      def merge!(new_props)
        new_props.each_key(&Houston::Props.method(:valid_prop_name!))
        @record.props = @hash = @hash.merge(new_props)
      end

      def delete!(key)
        @record.props = @hash = @hash.except(key)
      end

      def to_h
        @hash.dup
      end

      def respond_to_missing?(method_name, *args)
        return true if key?(method_name.to_s)
        super
      end

      def method_missing(method_name, *args, &block)
        prop_name = method_name.to_s
        return self[prop_name] if key?(prop_name)
        super
      end
    end

  end
end
